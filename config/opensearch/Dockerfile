ARG OPENSEARCH_VERSION=2.6.0
FROM opensearchproject/opensearch:$OPENSEARCH_VERSION
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch 'repository-s3' 'https://github.com/aiven/prometheus-exporter-plugin-for-opensearch/releases/download/2.6.0.0/prometheus-exporter-2.6.0.0.zip'