output "kafka_node_public_ip" {
  value       = aws_instance.kafka_node.public_ip
  description = "Public IP of Ubuntu Kafka Node"
}

output "kafka_bootstrap_server" {
  value       = "${aws_instance.kafka_node.public_ip}:9092"
  description = "Kafka Bootstrap Server endpoint"
}

output "ssh_kafka_command" {
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.kafka_node.public_ip}"
  description = "Command to SSH into the Kafka node"
}
