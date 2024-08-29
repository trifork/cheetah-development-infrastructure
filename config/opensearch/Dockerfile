FROM opensearchproject/opensearch:2.14.0

RUN /usr/share/opensearch/bin/opensearch-plugin install --batch 'repository-s3' 'https://github.com/Aiven-Open/prometheus-exporter-plugin-for-opensearch/releases/download/2.14.0.0/prometheus-exporter-2.14.0.0.zip' \
    && /usr/share/opensearch/bin/opensearch-plugin remove opensearch-security-analytics

#RUN /usr/share/opensearch/bin/opensearch-keystore create

COPY ./certs/key.pem /usr/share/opensearch/config/key.pem
COPY ./certs/public.pem /usr/share/opensearch/config/public.pem

RUN export ENCRYPTED_FS_DEFAULT_PRIVATE_KEY=$(cat /usr/share/opensearch/config/key.pem) \
    && export ENCRYPTED_FS_DEFAULT_PUBLIC_KEY=$(cat /usr/share/opensearch/config/public.pem) \
    && opensearch-keystore add-file --force encrypted.fs.default.private_key /usr/share/opensearch/config/key.pem \
    && opensearch-keystore add-file --force encrypted.fs.default.public_key /usr/share/opensearch/config/public.pem

RUN cat /usr/share/opensearch/config/key.pem
RUN /usr/share/opensearch/bin/opensearch-plugin install --batch 'https://github.com/Aiven-Open/encrypted-repository-opensearch/releases/download/v2.14.0.0/encrypted-repository-2.14.0.0.zip'

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD curl -u admin:admin -s -f opensearch:9200/_cat/health > /dev/null || exit 1
#trivy:ignore:avd-ds-0002
USER opensearch