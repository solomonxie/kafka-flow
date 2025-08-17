output "kafka_node_public_ip" {
  value       = aws_instance.kafka_node.public_ip
  description = "Public IP of Ubuntu Kafka Node"
}

output "kafka_node_public_dns" {
  value       = aws_instance.kafka_node.public_dns
  description = "Public DNS name of Ubuntu Kafka Node"
}

output "kafka_bootstrap_server" {
  value       = "${aws_instance.kafka_node.public_ip}:9092"
  description = "Kafka Bootstrap Server endpoint"
}

output "ssh_kafka_command" {
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.kafka_node.public_ip}"
  description = "Command to SSH into the Kafka node"
}

output "instance_id" {
  value       = "${aws_instance.kafka_node.id}"
  description = "EC2 instance ID"
}

output "aws_profile" {
  value       = "${var.aws_profile}"
  description = "Active AWS Profile"
}
