# Bridges Terraform to Ansible. local_file depends on all 3 instances'
# public_dns, so it can only run after they're all created — Terraform
# infers this from the references, no depends_on needed.
#
#   aws_instance.kafka_node{1,2,3}.public_dns
#           │
#           ▼
#   local_file.ansible_inventory  ──▶  ../ansible/inventory.ini
#                                         [kafka_brokers]
#                                         kafka_node1 ansible_host=<dns> node_id=1
#                                         kafka_node2 ansible_host=<dns> node_id=2
#                                         kafka_node3 ansible_host=<dns> node_id=3
#
# `make deploy-software` reads that generated file to target all 3 nodes;
# node_id feeds server.properties.j2's node.id / controller.quorum.voters.
# Dynamically generate latest server info for Ansible to access

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<EOF
[kafka_brokers]
kafka_node1 ansible_host=${aws_instance.kafka_node1.public_dns} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path} node_id=1
kafka_node2 ansible_host=${aws_instance.kafka_node2.public_dns} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path} node_id=2
kafka_node3 ansible_host=${aws_instance.kafka_node3.public_dns} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path} node_id=3
EOF
}
