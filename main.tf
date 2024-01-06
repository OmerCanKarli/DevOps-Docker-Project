terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

provider "github" {
  # Configuration options
  token = var.github-token
}

variable "key-name" {
  default = "firstkey"
}

variable "instance-type" {
  default = "t2.micro"
}

variable "github-token" {
  default = "XXXX"
}

variable "github-username" {
  default = "OmerCanKarli"
}

variable "files" {
  default = ["bookstore-api.py", "docker-compose.yml", "Dockerfile", "requirements.txt", "userdata.sh"]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance-type
  key_name               = var.key-name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  depends_on             = [github_repository.my_bookapp_repo, github_repository_file.my_bookapp_repo]
  user_data              = templatefile("${path.module}/userdata.sh", { token = var.github-token, user = var.github-username })
  tags = {
    Name = "Book Store Docker Machine"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "This security group allows port 22, 80 and port 8080 from anywhere."
  vpc_id      = data.aws_vpc.default.id
  tags = {
    Name = "ec2_sg"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "github_repository" "my_bookapp_repo" {
  name        = "my_bookapp_repo"
  description = "This repo created by Terraform."
  visibility  = "private"
  auto_init   = true
}

resource "github_repository_file" "my_bookapp_repo" {
  repository          = github_repository.my_bookapp_repo.name
  branch              = "main"
  for_each            = toset(var.files)
  file                = each.value
  content             = file(each.value)
  commit_message      = "Update"
  overwrite_on_create = true
}

resource "github_branch_default" "default" {
  repository = github_repository.my_bookapp_repo.name
  branch     = "main"
}

output "web_api_url" {
  value = "http://${aws_instance.ec2.public_dns}"
}
