FROM opensearchproject/opensearch:2.11.1
ARG UID=65534
ARG GID=1001
ARG OPENSEARCH_HOME=/usr/share/opensearch

RUN /usr/share/opensearch/bin/opensearch-plugin install --batch 'repository-s3' 'https://github.com/Aiven-Open/prometheus-exporter-plugin-for-opensearch/releases/download/2.11.1.0/prometheus-exporter-2.11.1.0.zip' \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-security-analytics \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-ml

# Ensure permissions are correct
USER root:root
RUN chown -R $UID:$GID $OPENSEARCH_HOME 
USER $UID
