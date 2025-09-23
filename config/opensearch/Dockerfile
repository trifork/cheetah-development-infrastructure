FROM opensearchproject/opensearch:3.2.0

RUN /usr/share/opensearch/bin/opensearch-plugin install --batch 'repository-s3' 'https://github.com/opensearch-project/opensearch-prometheus-exporter/releases/download/2.19.3.0/prometheus-exporter-2.19.3.0.zip' \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-security-analytics \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-skills \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-ml

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD curl -u admin:admin -s -f opensearch:9200/_cat/health > /dev/null || exit 1
#trivy:ignore:avd-ds-0002
USER opensearch