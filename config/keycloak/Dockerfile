FROM quay.io/adorsys/keycloak-config-cli:5.9.0-22.0.4

COPY ./keycloak_custom_role_creation.sh  /tmp/keycloak_custom_role_creation.sh 

USER root:root
# Make sure the directory exists and is owned by the right user
RUN mkdir -p /config && chown -R 65534:0 /config
RUN chown -R 65534:0 /tmp/keycloak_custom_role_creation.sh && chmod -R 777 /tmp/keycloak_custom_role_creation.sh
USER 65534