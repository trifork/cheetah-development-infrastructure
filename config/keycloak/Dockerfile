FROM quay.io/adorsys/keycloak-config-cli:5.9.0-22.0.4

USER root:root
# Make sure the directory exists and is owned by the right user
RUN  mkdir -p /config && chown -R 65534:0 /config && chmod -R g+rwX /config

USER 65534