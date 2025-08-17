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
# Specs: Ubuntu 26.04 (t2.small, 1 vCPU, 2GB RAM, 25GB EBS)

resource "aws_instance" "kafka_node1" {
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

resource "aws_instance" "kafka_node2" {
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

resource "aws_instance" "kafka_node3" {
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
