# Plain Ubuntu 22.04. The NVIDIA GPU Operator installs the driver, so the AMI
# deliberately has no NVIDIA software on it. That keeps the version matrix in
# one place (gpu-operator-values.yaml) instead of two.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "gpu_nodes" {
  name        = "gpu-cluster-nodes"
  description = "GPU cluster nodes: SSH from one CIDR, all traffic between nodes"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from the operator's IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Kubernetes, NCCL and the CNI all need node-to-node traffic. NCCL picks
  # ephemeral ports, so opening only a fixed list is a common cause of hangs
  # (RAID risk R4).
  ingress {
    description = "All traffic between cluster nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "gpu_node" {
  count = var.node_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.gpu_nodes.id]

  # Spread across subnets (and so AZs) in case one AZ has no g5 capacity (R6).
  subnet_id = element(data.aws_subnets.default.ids, count.index)

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  tags = {
    Name = "gpu-node-${count.index}"
    Role = count.index == 0 ? "control-plane+worker" : "worker"
  }
}
