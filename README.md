# kafka-flow

A hands-on playground for learning Apache Kafka — every experiment lives in its own
sub-project, each provisioning real infrastructure on AWS (Terraform) and installing
Kafka on it (Ansible), so concepts get tested against an actual running cluster rather
than just read about.

## Core concepts

- **Storage**: Topic / Partition / Offset / Page cache / Hot-Cold tier
- **Clustering**: Broker / Replication / ISR set / Cluster controller / Partition leader
- **Clients**: Producer / Consumer / Consumer group / Group coordinator

## Sub-projects

### [`kafka_helloworld/`](kafka_helloworld) — single-node broker

A minimal single EC2 instance running one Kafka broker in KRaft standalone mode.
Good starting point for basic producer/consumer mechanics: creating topics,
publishing/consuming events, partitions and offsets.

### [`kafka_cluster/`](kafka_cluster) — 3-node cluster

Three EC2 instances, each running Kafka as a combined broker+controller in KRaft mode,
forming a real quorum. Used to explore replication, ISR sets, and leader election —
e.g. killing a partition leader and watching the ISR set elect a new one.

```
                  ┌────────────────────────────────────────────────┐
                  │              Kafka Cluster                     │
                  │  (KRaft Controller Quorum: Nodes 1,2,3)        │
                  └────┬───────────────┬──────────────────────┬────┘
                       │               │                      │
            ┌──────────▼───┐       ┌───▼──────────┐       ┌───▼──────────┐
            │   Broker 1   │       │   Broker 2   │       │   Broker 3   │
            ├──────────────┤       ├──────────────┤       ├──────────────┤
            │  Topic:      │       │  Topic:      │       │  Topic:      │
            │  clickstream │       │  clickstream │       │  clickstream │
            │  P0 (Leader) │       │  P0 (Follow) │       │  P0 (Follow) │
            │  P1 (Follow) │       │  P1 (Leader) │       │  P1 (Follow) │
            │  P2 (Follow) │       │  P2 (Follow) │       │  P2 (Leader) │
            └──────────────┘       └──────────────┘       └──────────────┘
```

## Layout of each sub-project

Every sub-project follows the same structure:

```
<sub-project>/
├── terraform/      # provisions EC2 instance(s), security group, key pair
├── ansible/        # installs Java + Kafka, configures KRaft, runs it as a systemd service
├── manual_build.sh # same steps written out as manual shell commands, for learning
└── Makefile        # deploy-infra / deploy-software / destroy-infra / start-server / stop-server
```

Kafka runs in **KRaft mode** throughout (no ZooKeeper), on Ubuntu 26.04 `t2.small` EC2
instances, using Kafka 4.3.1.

## Usage

Each sub-project is self-contained. From inside `kafka_helloworld/` or `kafka_cluster/`:

```bash
make deploy-infra      # terraform apply — provision EC2 instance(s)
make deploy-software   # ansible-playbook — install & start Kafka
# ... play with the cluster ...
make stop-server        # stop EC2 instance(s) to save cost
make start-server        # start them back up
make destroy-infra      # terraform destroy — tear everything down
```

Or, to see every step spelled out by hand (useful for actually learning what's
happening under the hood), read through each project's `manual/build.sh`.

Requires: an AWS account/profile (`AWS_PROFILE`, default `prod`), Terraform, Ansible,
and an SSH key pair.
