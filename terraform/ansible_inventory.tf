# Dynamically generate latest server info for Ansible to access

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<EOF
[kafka_brokers]
kafka_node ansible_host=${aws_instance.kafka_node.public_dns} ansible_user=ubuntu ansible_ssh_private_key_file=${var.private_key_path}
EOF
}
