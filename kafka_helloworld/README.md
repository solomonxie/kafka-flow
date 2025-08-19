# kafka_helloworld

Single-node Kafka broker running in KRaft standalone mode. The simplest possible
setup — a good starting point for basic producer/consumer mechanics: creating
topics, publishing/consuming events, partitions and offsets.

## Where to look

- [`manual_build.sh`](manual_build.sh) — every step spelled out as raw shell
  commands: ssh in, install Kafka, format storage, start the broker, create
  topics, produce/consume. Start here to understand what's actually happening
  on the node — `ansible/` just automates these same steps.
- [`terraform/`](terraform) — provisions the EC2 instance, security group, and
  key pair. See [`terraform/README.md`](terraform/README.md) for the
  dependency graph.
- [`ansible/`](ansible) — installs Java + Kafka, configures `server.properties`,
  and runs Kafka as a systemd service.

## Usage

```bash
make deploy-infra      # terraform apply — provision the EC2 instance
make deploy-software   # ansible-playbook — install & start Kafka
# ... play with the broker, e.g. commands from manual_build.sh ...
make stop-server        # stop the instance to save cost
make start-server        # start it back up
make destroy-infra      # terraform destroy — tear everything down
```

Requires: an AWS account/profile (`AWS_PROFILE`, default `prod`), Terraform,
Ansible, and an SSH key pair.

## Self-termination

The EC2 instance auto-terminates ~2 hours after creation via an EventBridge
Scheduler rule (see [`terraform/auto_terminate.tf`](terraform/auto_terminate.tf))
— a cost safety net for a forgotten sandbox. It only terminates the instance;
run `make destroy-infra` afterward to clean up the rest (security group, key
pair).
