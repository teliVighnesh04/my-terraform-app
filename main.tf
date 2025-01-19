terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "terratest-prod"
    workspaces {
      name = "my-aws-app2"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}


variable "environment" {
  type        = string
  description = "Infrastructure environment. eg. dev, prod, etc"
  default     = "test"
}

variable "vpc_name" {
  type        = string
}

variable "cidr_block" {}

variable "availability_zone" {}

variable "public_subnet_cidr_block" {
  type = list(string)
}

#vpc
resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr_block
  tags = {
    "env" = "Practice"
    "Name"= var.vpc_name
    "env"= var.environment
  }
}

#igw
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    "env" = "Practice"
  }
}

#subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_cidr_block[0]
  availability_zone = var.availability_zone
  tags = {
    "env" = "Practice"
  }
}

#route table
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    "name" = "main"
  }
}

resource "aws_route_table_association" "a" {
  route_table_id = aws_route_table.public_rtb.id
  subnet_id      = aws_subnet.public_subnet.id
}


#security group
resource "aws_security_group" "my_sg" {
  name        = "allow tls"
  description = "allow ssh and http"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "TLS from VPC"
    from_port   = 00
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "main"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  availability_zone           = var.availability_zone
  key_name                    = "terraform"
  security_groups             = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  user_data                   = <<EOF
                  #!/bin/bash
                  sudo apt update
                  sudo apt install nginx -y
                  sudo systemctl start nginx
                  exit 0
              EOF
  tags = {
    "env" = "Practice"
  }
}

resource "aws_instance" "web22" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  availability_zone           = var.availability_zone
  key_name                    = "terraform"
  security_groups             = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  tags = {
    "Name" = "Dev Instance"
    "env" = var.environment
  }
}




