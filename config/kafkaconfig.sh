#!/usr/bin bash

# echo "Waiting for Kafka to be ready..."
# cub kafka-ready -b kafka:19093 1 20 #expected_brokers timeout_seconds

# for user in redpanda-user; do
bash bin/kafka-configs.sh --bootstrap-server kafka:19092 --command-config /etc/config/producer.config --alter --add-config 'SCRAM-SHA-512=[password=password]' --entity-type users --entity-name redpanda

echo "Creating topics with retention set to 3 years"
for topic in OttoReadingMovingAverage OttoReading OttoReadingId JobNameInputTopic; do
   bash bin/kafka-topics.sh --create --if-not-exists --bootstrap-server kafka:19092 --command-config /etc/config/producer.config --partitions 1 --replication-factor 1 --topic $topic --config retention.ms=20000
   bash bin/kafka-configs.sh --bootstrap-server kafka:19092 --command-config /etc/config/producer.config --entity-type topics --entity-name $topic --alter --add-config segment.bytes=300
done
echo "Creating topics done"

# Alter in case they already existed
## Options:
#cleanup.policy
#compression.type
#delete.retention.ms
#file.delete.delay.ms
#flush.messages
#flush.ms
#follower.replication.throttled.replicas
#index.interval.bytes
#leader.replication.throttled.replicas
#max.compaction.lag.ms
#max.message.bytes
#message.downconversion.enable
#message.format.version
#message.timestamp.difference.max.ms
#message.timestamp.type
#min.cleanable.dirty.ratio
#min.compaction.lag.ms
#min.insync.replicas
#preallocate
#retention.bytes
#retention.ms
#segment.bytes
#segment.index.bytes
#segment.jitter.ms
#segment.ms
#unclean.leader.election.enable

# bash bin/kafka-topics.sh --create --if-not-exists --bootstrap-server kafka:19093 --partitions 1 --replication-factor 1 --topic $topic --config retention.ms=20000 segment.bytes=300
#    bash bin/kafka-configs.sh --alter --bootstrap-server kafka:19093 --topic $topic --config segment.bytes=300 