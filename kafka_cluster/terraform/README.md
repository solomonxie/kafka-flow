# Terraform

Provisions 3 EC2 nodes for the Kafka broker/controller quorum and hands
their addresses off to Ansible. Terraform builds an execution plan by
resolving attribute references between resources into a dependency graph —
file order doesn't matter, reference order does. See each file's head
comment for its place in that graph.

```
terraform apply
  ├─ providers.tf         → auth against AWS
  ├─ variables.tf         → resolve inputs
  ├─ ec2.tf                → sg + key pair + ami lookup → aws_instance x3 (node1/2/3, parallel)
  ├─ ansible_inventory.tf → write ansible/inventory.ini (node_id=1/2/3)
  └─ outputs.tf            → print IPs / bootstrap servers / ssh commands
        │
        ▼
ansible-playbook -i ansible/inventory.ini ansible/site.yml   (deploy-software)
  → each node's node.id / controller.quorum.voters rendered from inventory
```
