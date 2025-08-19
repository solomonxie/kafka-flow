# The core resource graph.
# 3 independent resources build in parallel,
# and the instance waits on all three:
#
#   aws_security_group.kafka_sg         (no deps — SSH 22, Kafka 9092)
#   aws_key_pair.deployer               (no deps — reads var.public_key_path)
#   data.aws_ami.ubuntu_2604            (no deps — queried from AWS API)
#           │
#           ▼
#   aws_instance.kafka_node
#     ├─ ami                    = data.aws_ami.ubuntu_2604.id
#     ├─ key_name               = aws_key_pair.deployer.key_name
#     └─ vpc_security_group_ids = [aws_security_group.kafka_sg.id]

# --- Security Group for Kafka ---
resource "aws_security_group" "kafka_sg" {
  name        = "kafka-node-sg"
  description = "Allow inbound traffic for Kafka and SSH"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka Broker Port"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kafka-security-group"
  }
}

# --- Key Pair ---
resource "aws_key_pair" "deployer" {
  key_name   = "kafka-key"
  public_key = file(var.public_key_path)
}

# --- AMI Lookups ---

# Ubuntu 26.04 LTS (x86_64)
data "aws_ami" "ubuntu_2604" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-*-26.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# --- EC2 Instances ---

# 1. Kafka Node: Ubuntu 26.04 (t2.small, 1 vCPU, 2GB RAM, 25GB EBS)
resource "aws_instance" "kafka_node" {
  ami                    = data.aws_ami.ubuntu_2604.id
  instance_type          = "t2.small"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.kafka_sg.id]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "kafka-ubuntu-node"
    Role        = "kafka-broker"
    Environment = "production"
  }
}
