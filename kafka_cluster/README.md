# kafka_cluster

Three EC2 instances, each running Kafka as a combined broker+controller in
KRaft mode, forming a real quorum. Used to explore replication, ISR sets, and
leader election — e.g. killing a partition leader and watching the ISR set
elect a new one.

**Kafka core concepts**:

- Storage: Topic / Partition / Offset / Page cache / Hot-Cold tier
- Clustering: Broker / Replication / ISR set / Cluster controller / Partition leader
- Clients: Producer / Consumer / Consumer group / Group coordinator

**Design**:

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

## Where to look

- [`manual_build.sh`](manual_build.sh) — every step spelled out as raw shell
  commands: ssh into each node, install Kafka, edit `server.properties` for
  KRaft quorum voters, format storage with a shared cluster ID, start each
  broker, then create a replicated topic and kill a leader to watch failover.
  Start here to understand what's actually happening on the nodes —
  `ansible/` just automates these same steps.
- [`terraform/`](terraform) — provisions the 3 EC2 instances, security group,
  and key pair. See [`terraform/README.md`](terraform/README.md) for the
  dependency graph.
- [`ansible/`](ansible) — installs Java + Kafka on each node, renders each
  node's `node.id` / `controller.quorum.voters` from the Terraform-generated
  inventory, and runs Kafka as a systemd service.

## Usage

```bash
make deploy-infra      # terraform apply — provision the 3 EC2 instances
make deploy-software   # ansible-playbook — install & start Kafka on all 3
# ... play with the cluster, e.g. commands from manual_build.sh ...
make stop-server        # stop the instances to save cost
make start-server        # start them back up
make destroy-infra      # terraform destroy — tear everything down
```

Requires: an AWS account/profile (`AWS_PROFILE`, default `prod`), Terraform,
Ansible, and an SSH key pair.

## Self-termination

All 3 EC2 instances auto-terminate ~2 hours after creation via a single
EventBridge Scheduler rule (see
[`terraform/auto_terminate.tf`](terraform/auto_terminate.tf)) — a cost safety
net for a forgotten cluster. It only terminates the instances; run
`make destroy-infra` afterward to clean up the rest (security group, key pair).
