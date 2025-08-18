# Prepare 3x EC2 servers (t2.small, 1 vCPU, 2GB memory, 64bit x86, Ubuntu 26.04)

ssh ubuntu@$node1_ip -i ~/.ssh/mykeypairxxxx.pem


# 1. Install Kafka
sudo apt update
sudo apt install -y openjdk-17-jre-headless wget tar
wget -O /tmp/kafka.tgz https://downloads.apache.org/kafka/4.3.1/kafka_2.13-4.3.1.tgz
sudo mkdir -p /opt/kafka
sudo tar -xzf /tmp/kafka.tgz -C /opt/kafka --strip-components=1
sudo chown -R ubuntu:ubuntu /opt/kafka
cd /opt/kafka

# Change Kafka configs
vim /opt/kafka/config/server.properties
# Change these:
- process.roles=...  # ==> make sure it's KRaft mode
+ process.roles=broker,controller
- node.id=1  # ==> give it a unique integer, to distinguish from other nodes
+ node.id=1  # or 1/2/3
- controller.quorum.bootstrap.servers=...  # ==> this is dynamic quorum, we need a static quorum
+ controller.quorum.voters=1@node1_ip:9093,2@node2_ip:9093,3@node3_ip:9093
- listeners=PLAINTEXT://:9092,CONTROLLER://:9093  # open to local or public IP
+ listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
- advertised.listeners=PLAINTEXT://localhost:9092,CONTROLLER://localhost:9093
+ advertised.listeners=PLAINTEXT://current_node_public_ip:9092
- log.dirs=/tmp/kraft-combined-logs
+ log.dirs=/var/lib/kafka-logs


# Create the directory Kafka will write its logs/metadata to
sudo mkdir -p /var/lib/kafka-logs
sudo chown -R ubuntu:ubuntu /var/lib/kafka-logs

# Format storage with the shared cluster ID — (run only once)
export CLUSTER_ID=IxqT0OtiQfqRl3kGlGV6tQ
sudo bin/kafka-storage.sh format -t $CLUSTER_ID -c config/server.properties
sudo chown -R ubuntu:ubuntu /var/lib/kafka-logs

# Manually run server in the foreground (open another shell for another node)
# note: can add KAFKA_HEAP_OPTS="-Xmx512M -Xms512M" option to protect mem
nohup /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties >> /tmp/kafka.log 2>&1 &

# ^^^ repeat the all above steps on node2/node3

# Test if cluster is up: (test only succeed after all 3 nodes are setup)
telnet 127.0.0.1 9092

# =====================================================================
# ============== ONCE ALL 3 NODES ABOVE ARE RUNNING ===================
# =====================================================================
# Any single broker can act as the bootstrap server to talk to the whole cluster.

# Sanity check the cluster is reachable
bin/kafka-topics.sh --bootstrap-server node1_ip:9092 --list

# Create a topic replicated across all 3 brokers (replication-factor 3 needs 3 live brokers)
bin/kafka-topics.sh --create \
  --bootstrap-server node1_ip:9092 \
  --replication-factor 3 \
  --partitions 3 \
  --topic clickstream-raw
# >> Created topic clickstream-raw.

# See which broker leads/replicates each partition
bin/kafka-topics.sh --describe --bootstrap-server node1_ip:9092 --topic clickstream-raw
# >> Topic: clickstream-raw  PartitionCount: 3  ReplicationFactor: 3
# >>   Partition: 0  Leader: 2  Replicas: 2,3,1  Isr: 2,3,1
# >>   Partition: 1  Leader: 3  Replicas: 3,1,2  Isr: 3,1,2
# >>   Partition: 2  Leader: 1  Replicas: 1,2,3  Isr: 1,2,3

# Produce / consume against the whole cluster (listing all 3 as bootstrap servers
# means the client survives any single broker being down)
bin/kafka-console-producer.sh --bootstrap-server node1_ip:9092,node2_ip:9092,node3_ip:9092 --topic clickstream-raw
# >> {"event_type":"view", "user_id":1001, "price":15.50}

bin/kafka-console-consumer.sh --bootstrap-server node1_ip:9092,node2_ip:9092,node3_ip:9092 --topic clickstream-raw --from-beginning

# Kill the current partition leader for a partition and re-describe the topic to
# watch the ISR set elect a new leader — this is the whole point of clustering.
