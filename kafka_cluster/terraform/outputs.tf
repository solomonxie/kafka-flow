output "kafka_node_public_ips" {
  value = {
    node1 = aws_instance.kafka_node1.public_ip
    node2 = aws_instance.kafka_node2.public_ip
    node3 = aws_instance.kafka_node3.public_ip
  }
  description = "Public IPs of Kafka nodes"
}

output "kafka_node_public_dns" {
  value = {
    node1 = aws_instance.kafka_node1.public_dns
    node2 = aws_instance.kafka_node2.public_dns
    node3 = aws_instance.kafka_node3.public_dns
  }
  description = "Public DNS names of Kafka nodes"
}

output "kafka_bootstrap_servers" {
  value = join(",", [
    "${aws_instance.kafka_node1.public_ip}:9092",
    "${aws_instance.kafka_node2.public_ip}:9092",
    "${aws_instance.kafka_node3.public_ip}:9092",
  ])
  description = "Kafka bootstrap server list (all 3 brokers)"
}

output "ssh_kafka_commands" {
  value = {
    node1 = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.kafka_node1.public_ip}"
    node2 = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.kafka_node2.public_ip}"
    node3 = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.kafka_node3.public_ip}"
  }
  description = "Commands to SSH into each Kafka node"
}

output "instance_ids" {
  value = {
    node1 = aws_instance.kafka_node1.id
    node2 = aws_instance.kafka_node2.id
    node3 = aws_instance.kafka_node3.id
  }
  description = "EC2 instance IDs"
}

output "instance_ids_space_separated" {
  value = join(" ", [
    aws_instance.kafka_node1.id,
    aws_instance.kafka_node2.id,
    aws_instance.kafka_node3.id,
  ])
  description = "EC2 instance IDs, space-separated (for aws cli --instance-ids)"
}

output "aws_profile" {
  value       = var.aws_profile
  description = "Active AWS Profile"
}
