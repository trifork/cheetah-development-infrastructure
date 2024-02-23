FROM quay.io/adorsys/keycloak-config-cli:5.10.0-22.0.4

COPY ./keycloak_custom_role_creation.sh  /tmp/keycloak_custom_role_creation.sh 

USER root:root

RUN mkdir -p /config && chown -R 65534:0 /config
RUN chmod +x /tmp/keycloak_custom_role_creation.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=10 CMD test -e /config/local-development.json || exit 1

ENTRYPOINT ["/bin/sh", "-c", "/tmp/keycloak_custom_role_creation.sh /tmp/local-development.json /config/local-development.json && exec java $JAVA_OPTS -jar /app/keycloak-config-cli.jar $0 $@"]
# nobody user
USER 65534