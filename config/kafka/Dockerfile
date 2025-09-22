# Use mwendler/wget to build the connector
FROM mwendler/wget:latest AS build

# Set working directory to /tmp
WORKDIR /tmp

# Create a directory for the connector
RUN mkdir opensearch-connector-for-apache-kafka-3.1.1

# Download the connector zip file
RUN wget https://github.com/Aiven-Open/opensearch-connector-for-apache-kafka/releases/download/v3.1.1/opensearch-connector-for-apache-kafka-3.1.1.zip --no-check-certificate

# Unzip the connector into the created directory
RUN unzip opensearch-connector-for-apache-kafka-3.1.1.zip -d opensearch-connector-for-apache-kafka-3.1.1

# Use Strimzi Kafka as the base image
FROM quay.io/strimzi/kafka:0.40.0-kafka-3.7.0

# Switch to root user to copy files
USER root:root

# Copy the connector from the build stage to the plugins directory
COPY --from=build /tmp/opensearch-connector-for-apache-kafka-3.1.1 /opt/kafka/plugins/

# Switch back to non-root user
USER 1001
