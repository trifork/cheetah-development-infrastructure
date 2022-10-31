#!/usr/bin/env python3
import json
import os
import sys
import difflib

import requests

if len(sys.argv) < 2:
    print('Provide the ES host as an argument')

    exit(-1)

host = sys.argv[1]
dev_mode = '--dev' in sys.argv[2:]
diff_mode = '--diff' in sys.argv[2:]


def get_difference(expected, actual):
    return ''.join(difflib.unified_diff(expected.splitlines(1), actual.splitlines(1)))

def print_difference_if_any(existing, new, message):
    new_pretty = json.dumps(new, indent=2, sort_keys=True)
    existing_pretty = json.dumps(existing, indent=2, sort_keys=True)

    difference = get_difference(existing_pretty, new_pretty)
    if difference:
        print(f'\n{message}')

        print(difference)

def pack(parts, value):
    if len(parts) == 0:
        return value
    elif len(parts) == 1:
        return {parts[0]: value}
    elif len(parts):
        return {parts[0]: pack(parts[1:], str(value))}

    return {}


def merge_dicts(source, destination):
    for key, value in source.items():
        if isinstance(value, dict):
            destination_node = destination.setdefault(key, {})
            merge_dicts(value, destination_node)
        else:
            if key not in destination:
                destination[key] = value


def get_files(directory, extension):
    return [file for file in os.listdir(directory) if file.endswith(extension)]


def normalize(from_template, of_type):
    template = from_template.copy()

    # Normalize cluster settings
    if of_type == 'cluster' and 'transient' not in from_template:
        template['transient'] = {}
    
    # Normalize lifecycle policy
    if of_type == 'lifecycle' and 'policy' in from_template:
        for phase in from_template.get('policy', {}).get('phases', {}).values():
            # Set minimum age to 0 ms, if not specified 
            if 'min_age' not in phase:
                phase['min_age'] = '0ms'

            # Expand implicit settings for ILM phases
            phase_actions = phase.get('actions', {})
            if 'migrate' in phase_actions and not phase_actions.get('migrate', {}):
                phase_actions['migrate'] = {'enabled': True}
            
            if 'delete' in phase_actions and not phase_actions.get('delete', {}):
                phase_actions['delete'] = {'delete_searchable_snapshot': True}

    # Normalizes a new template with transformations done by ES s.t. diff can be made
    if of_type == 'index' and 'composed_of' not in template:
        template['composed_of'] = []

    settings = template.get('template', {}).get('settings', {})
    if not settings:
        return template

    stringify_fields = {'number_of_replicas', 'number_of_shards'}
    for stringify_field in stringify_fields:
        if stringify_field in settings:
            settings[stringify_field] = str(settings[stringify_field])
        
    # ES moves everything under settings to an index object
    index_settings = settings.get('index', {})
    for setting, value in settings.copy().items():
        if setting == 'index':
            continue

        if '.' in setting:
            setting_parts = setting.split('.')
            if setting_parts[0] == 'index':
                setting_parts = setting_parts[1:]

            # ES expands paths (e.g., lifecycle.name) to dicts
            root_part = setting_parts[0]
            remaining_part = pack(setting_parts[1:], value)
            if root_part in index_settings:
                merge_dicts(index_settings[root_part], remaining_part)
            index_settings[root_part] = remaining_part
        else:
            index_settings[setting] = value

        # Remove the moved setting
        del settings[setting]

    settings['index'] = index_settings

    return template


def apply_lifecycles():
    base_dir = './lifecycle_policies'

    for file in get_files(base_dir, '.json'):
        name = os.path.splitext(file)[0]
        print(f'Applying {name} lifecycle policy...')

        with open(os.path.join(base_dir, file), 'r') as fp:
            lifecycle_json = json.load(fp)
            lifecycle_url = f'http://{host}/_ilm/policy/{name}_policy'

            if diff_mode:
                existing_response = requests.get(lifecycle_url)
                if existing_response.status_code != 200:
                    print(f'No existing lifecycle for {name}')

                    return True

                existing_policy = existing_response.json().get(f'{name}_policy')
                if not existing_policy:
                    print(f'Lifecycle {name} not found in response JSON')

                    return True

                for key in {'in_use_by', 'version', 'modified_date'}:
                    if key in existing_policy:
                        del existing_policy[key]

                print_difference_if_any(existing_policy, normalize(lifecycle_json, 'lifecycle'), f'Lifecycle {name} has changes')
            else:
                res = requests.put(lifecycle_url, json=lifecycle_json)

                if res.status_code != 200:
                    print(f'Something went wrong with lifecycle policy {name}: {res.text}')

                    return False

    return True


def apply_pipelines():
    base_dir = './pipelines'

    for file in get_files(base_dir, '.json'):
        name = os.path.splitext(file)[0]
        print(f'Applying {name} pipeline...')

        with open(os.path.join(base_dir, file), 'r') as fp:
            pipeline_json = json.load(fp)
            pipeline_url = f'http://{host}/_ingest/pipeline/{name}_pipeline'

            if diff_mode:
                existing_response = requests.get(pipeline_url)
                if existing_response.status_code != 200:
                    print(f'No existing pipeline for {name}')

                    return True

                existing_pipeline = existing_response.json().get(f'{name}_pipeline')
                if not existing_pipeline:
                    print(f'Pipeline {name} not found in response JSON')

                    return True

                print_difference_if_any(existing_pipeline, normalize(pipeline_json, 'pipeline'), f'Pipeline {name} has changes')
            else:
                res = requests.put(pipeline_url, json=pipeline_json)

                if res.status_code != 200:
                    print(f'Something went wrong with pipeline {name}: {res.text}')

                    return False

    return True


def apply_templates(of_type):
    base_dir = f'./{of_type}_templates'

    for file in get_files(base_dir, '.json'):
        name = os.path.splitext(file)[0]
        print(f'Applying {name} template...')

        with open(os.path.join(base_dir, file), 'r') as fp:
            template_json = json.load(fp)
            if template_json and dev_mode:
                template_settings = template_json.get('template', {}).get('settings', {})

                if template_settings:
                    print(f'Overriding shard and replica settings for {name}...')

                    template_settings['number_of_shards'] = '1'
                    template_settings['number_of_replicas'] = '0'

            template_url = f'http://{host}/_{of_type}_template/{name}_template'
            if diff_mode:
                existing_response = requests.get(template_url)
                if existing_response.status_code != 200:
                    print(f'No existing template for {name}')

                    return True

                existing_json = existing_response.json()
                if existing_json:
                    template_list = existing_json.get(f'{of_type}_templates', [])

                    if not template_list:
                        print(f'No {of_type} templates found in response from {name}')

                        return True

                    existing_template = template_list[-1].get(f'{of_type}_template')

                print_difference_if_any(existing_template, normalize(template_json, of_type), f'{of_type.capitalize()} template {name} has changes')
            else:
                res = requests.put(template_url, json=template_json)

                if res.status_code != 200:
                    print(f'Something went wrong with {of_type} template {name}: {res.text}')

                    return False

    return True


def apply_cluster_settings():
    base_dir = f'./cluster'
    url = f'http://{host}/_cluster/settings?flat_settings=true'

    for file in get_files(base_dir, '.json'):
        name = os.path.splitext(file)[0]
        print(f'Applying {name} cluster settings...')

        with open(os.path.join(base_dir, file), 'r') as fp:
            cluster_json = json.load(fp)

            if diff_mode:
                existing_response = requests.get(url)
                if existing_response.status_code != 200:
                    print(f'No existing cluster settings found')

                    return True

                print_difference_if_any(existing_response.json(), normalize(cluster_json, 'cluster'), f'Cluster settings {name} has changes')
            else:
                res = requests.put(url, json=cluster_json)

                if res.status_code != 200:
                    print(f'Something went wrong with applying cluster setting from {name}: {res.text}')

                    return False


if __name__ == '__main__':
    apply_lifecycles() and apply_pipelines() and apply_templates('component') and apply_templates('index') and apply_cluster_settings()
