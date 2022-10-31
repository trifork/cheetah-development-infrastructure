# Elasticsearch Configuration
To apply the configuration to `localhost:9200`:
```
python3 apply_configuration.py localhost:9200 --dev
```

Supply `--dev` as an argument to override shard and replica settings.
When overriding, `number_of_shards` will be set to 1, and `number_of_replicas` will be set to 0.

Supply `--diff` as an argument to apply the configuration as a dry-run.
This option will show any differences in index and component templates that would result from a wet run.

```
python3 apply_configuration.py https://elasticsearch.skagerak.trifork.dev:9200 --dev

```