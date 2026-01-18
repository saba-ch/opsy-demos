# VPC Peering Demo

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  az1 = data.aws_availability_zones.azs.names[0]
  az2 = data.aws_availability_zones.azs.names[1]
}

# VPC A (Clients)
resource "aws_vpc" "a" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "demo-vpc-a" }
}

resource "aws_internet_gateway" "a" {
  vpc_id = aws_vpc.a.id
  tags   = { Name = "demo-igw-a" }
}

resource "aws_subnet" "a1" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = local.az1
  map_public_ip_on_launch = true
  tags                    = { Name = "demo-a-subnet-1" }
}

resource "aws_subnet" "a2" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = local.az2
  map_public_ip_on_launch = true
  tags                    = { Name = "demo-a-subnet-2" }
}

resource "aws_route_table" "a_rt" {
  vpc_id = aws_vpc.a.id
  tags   = { Name = "demo-a-rt" }
}

resource "aws_route" "a_default_igw" {
  route_table_id         = aws_route_table.a_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.a.id
}

resource "aws_route_table_association" "a1_assoc" {
  subnet_id      = aws_subnet.a1.id
  route_table_id = aws_route_table.a_rt.id
}

resource "aws_route_table_association" "a2_assoc" {
  subnet_id      = aws_subnet.a2.id
  route_table_id = aws_route_table.a_rt.id
}

# VPC B (Server)
resource "aws_vpc" "b" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "demo-vpc-b" }
}

resource "aws_internet_gateway" "b" {
  vpc_id = aws_vpc.b.id
  tags   = { Name = "demo-igw-b" }
}

resource "aws_subnet" "b1" {
  vpc_id                  = aws_vpc.b.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = local.az1
  map_public_ip_on_launch = true
  tags                    = { Name = "demo-b-subnet-1" }
}

resource "aws_route_table" "b_rt" {
  vpc_id = aws_vpc.b.id
  tags   = { Name = "demo-b-rt" }
}

resource "aws_route" "b_default_igw" {
  route_table_id         = aws_route_table.b_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.b.id
}

resource "aws_route_table_association" "b1_assoc" {
  subnet_id      = aws_subnet.b1.id
  route_table_id = aws_route_table.b_rt.id
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = aws_vpc.a.id
  peer_vpc_id = aws_vpc.b.id
  auto_accept = true
  tags        = { Name = "demo-a-b-peering" }
}

# Route from VPC A to VPC B
resource "aws_route" "a_to_b" {
  route_table_id            = aws_route_table.a_rt.id
  destination_cidr_block    = aws_vpc.b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# Route from VPC B to VPC A
resource "aws_route" "b_to_a" {
  route_table_id            = aws_route_table.b_rt.id
  destination_cidr_block    = "10.10.1.0/24"
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# Security Groups
resource "aws_security_group" "clients_sg" {
  name        = "demo-clients-sg"
  description = "Clients security group"
  vpc_id      = aws_vpc.a.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "demo-clients-sg" }
}

resource "aws_security_group" "server_sg" {
  name        = "demo-server-sg"
  description = "Allow HTTP from VPC A"
  vpc_id      = aws_vpc.b.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.a.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "demo-server-sg" }
}

# IAM Role for SSM
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_iam_role" "ssm_role" {
  name               = "demo-ssm-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "demo-ssm-profile-${random_id.suffix.hex}"
  role = aws_iam_role.ssm_role.name
}

# EC2 Instances
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "server" {
  ami                    = data.aws_ami.al2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.b1.id
  vpc_security_group_ids = [aws_security_group.server_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum -y install python3
    cd /tmp
    echo "hello from VPC B server" > index.html
    nohup python3 -m http.server 8080 --bind 0.0.0.0 &
    EOF

  tags = { Name = "demo-server" }
}

resource "aws_instance" "client_1" {
  ami                    = data.aws_ami.al2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.a1.id
  vpc_security_group_ids = [aws_security_group.clients_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  tags = { Name = "demo-client-1" }
}

resource "aws_instance" "client_2" {
  ami                    = data.aws_ami.al2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.a2.id
  vpc_security_group_ids = [aws_security_group.clients_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  tags = { Name = "demo-client-2" }
}
