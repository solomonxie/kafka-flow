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
