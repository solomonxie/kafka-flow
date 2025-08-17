# Prepare EC2: t2.small, 1 vCPU, 2GB memory, 64bit x86, Ubuntu 26.04 (easier for Kafka runtime)


ssh ubuntu@ec2-xxxxxxxx.compute-1.amazonaws.com -i ~/.ssh/mykeypairxxxxx.pem

sudo apt update && sudo apt install wget


# Install Apache Kafka (3.8.0) -- https://kafka.apache.org/community/downloads/
wget -O kafka.tgz https://www.apache.org/dyn/closer.lua/kafka/4.3.1/kafka_2.13-4.3.1.tgz?action=download
tar -xzf kafka.tgz && rm kafka.tgz
cd kafka_2.13-4.3.1
export KAFKA_HEAP_OPTS="-Xmx512M -Xms512M"  # Set Kafka heap size limit
export CLUSTER_ID=$(bin/kafka-storage.sh random-uuid)  # Generate a cluster ID
# >> IxqT0OtiQfqRl3kGlGV6tQ

bin/kafka-storage.sh format --standalone -t $CLUSTER_ID -c config/server.properties  # Initial Format storage
# >> ... Formatting dynamic metadata voter directory /tmp/kraft-combined-logs with metadata.version 4.3-IV0.

# Start Kafka server in the background (default port :9092, change in the config)
bin/kafka-server-start.sh -daemon config/server.properties
# >> it will launch many processes in the back, very long commands
# verify it's running:
bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Create topics
bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 1 \
  --partitions 3 \
  --topic clickstream-raw
# >> Created topic clickstream-raw.
bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 1 \
  --partitions 1 \
  --topic purchases-high-value
# >> Created topic purchases-high-value.
# verify:
bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
# >> clickstream-raw
# >> purchases-high-value

# Manually publish an event: (manually type events)
bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic clickstream-raw
# >> {"event_type":"view", "user_id":1001, "price":15.50}
# >> {"event_type":"purchase", "user_id":1002, "price":250.00}
bin/kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic clickstream-raw
# >> clickstream-raw:0:0
# >> clickstream-raw:1:3  -- only this partition has 3 events
# >> clickstream-raw:2:0
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic clickstream-raw --from-beginning  # --from-beginning shows all events instead of new coming only
