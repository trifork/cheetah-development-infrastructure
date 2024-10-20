FROM opensearchproject/opensearch:2.17.1

RUN /usr/share/opensearch/bin/opensearch-plugin install --batch 'repository-s3' 'https://github.com/Aiven-Open/prometheus-exporter-plugin-for-opensearch/releases/download/2.15.0.0/prometheus-exporter-2.15.0.0.zip' \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-security-analytics \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-skills \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-ml

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD curl -u admin:admin -s -f opensearch:9200/_cat/health > /dev/null || exit 1
#trivy:ignore:avd-ds-0002
USER opensearch