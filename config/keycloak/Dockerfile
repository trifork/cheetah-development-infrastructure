FROM quay.io/adorsys/keycloak-config-cli:5.9.0-22.0.4

COPY ./keycloak_custom_role_creation.sh  /tmp/keycloak_custom_role_creation.sh 

USER root:root

RUN mkdir -p /config && chown -R 65534:0 /config
RUN chmod +x /tmp/keycloak_custom_role_creation.sh

HEALTHCHECK --interval=1s --timeout=1s --start-period=1s --retries=3 CMD test -e /config/local-development.json || exit 1

ENTRYPOINT ["/bin/sh", "-c", "/tmp/keycloak_custom_role_creation.sh /tmp/local-development.json /config/local-development.json && exec java $JAVA_OPTS -jar /app/keycloak-config-cli.jar $0 $@"]
USER 65534