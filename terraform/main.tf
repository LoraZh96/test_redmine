terraform {
  cloud {
    organization = "anironi-terraform"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = " >= 1.2.0"
}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_key_pair" "team" {
  key_name   = "team-temp-key"
  public_key = file("${path.module}/keys/team-temp-key.pub")

  tags = {
    Name    = "temporary-shared-key"
    Purpose = "Infra bootstrap before Ansible roles"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gw"
  }
}

# Public Subnet

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

# Private Subnets

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "eu-west-3b"

  tags = {
    Name = "private-subnet-b"
  }
}

# Route Table publique

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}
# Subnet publique + route publique

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Route Table privée

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt"
  }
}

# Subnet privee + route privee 

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}


# EC2
resource "aws_instance" "proxy" {
  ami             = "ami-0308d3033923f20b2"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.public_a.id
  key_name        = aws_key_pair.team.key_name
  security_groups = [aws_security_group.sec-grp-revproxy.id]

  # User Data
  user_data = templatefile("./user_data.sh", {
    server_tag = "PROXY"
    ssh_keys   = var.ssh_public_keys
  })

  tags = {
    Name = "PROXY"
  }
}

resource "aws_instance" "bastion" {
  ami             = "ami-0308d3033923f20b2"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.public_a.id
  key_name        = aws_key_pair.team.key_name
  security_groups = [aws_security_group.sec-grp-bastion.id]

  # User Data
  user_data = templatefile("./user_data.sh", {
    server_tag = "BASTION"
    ssh_keys   = var.ssh_public_keys
  })

  tags = {
    Name = "BASTION"
  }
}

resource "aws_instance" "manager" {
  ami             = "ami-0308d3033923f20b2"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.private_a.id
  key_name        = aws_key_pair.team.key_name
  security_groups = [aws_security_group.sec-grp-app.id]

  # User Data
  user_data = templatefile("./user_data.sh", {
    server_tag = "MANAGER"
    ssh_keys   = var.ssh_public_keys
  })

  tags = {
    Name = "MANAGER"
  }
}

resource "aws_instance" "worker1" {
  ami             = "ami-0308d3033923f20b2"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.private_a.id
  key_name        = aws_key_pair.team.key_name
  security_groups = [aws_security_group.sec-grp-app.id]

  # User Data
  user_data = templatefile("./user_data.sh", {
    server_tag = "WORKER1"
    ssh_keys   = var.ssh_public_keys
  })

  tags = {
    Name = "WORKER1"
  }
}

resource "aws_instance" "worker2" {
  ami             = "ami-0308d3033923f20b2"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.private_b.id
  key_name        = aws_key_pair.team.key_name
  security_groups = [aws_security_group.sec-grp-app.id]

  # User Data
  user_data = templatefile("./user_data.sh", {
    server_tag = "WORKER2"
    ssh_keys   = var.ssh_public_keys
  })

  tags = {
    Name = "WORKER2"
  }
}

resource "aws_instance" "monitoring" {
  ami             = "ami-0308d3033923f20b2"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.private_a.id
  key_name        = aws_key_pair.team.key_name
  security_groups = [aws_security_group.sec-grp-monitor.id]

  # User Data
  user_data = templatefile("./user_data.sh", {
    server_tag = "MONITORING"
    ssh_keys   = var.ssh_public_keys
  })

  tags = {
    Name = "MONITORING"
  }
}

# Subnet group

resource "aws_db_subnet_group" "redmine_db_subnet_group" {
  name = "redmine-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "redmine-db-subnet-group"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "redmine_db" {
  identifier          = "redmine-db"
  allocated_storage   = 20
  engine              = "postgres"
  engine_version      = "17.6"
  instance_class      = "db.t3.micro"
  db_name             = "redmine"
  username            = var.db_username
  password            = var.redmine_db_password
  port                = 5432
  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.redmine_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sec-grp-db.id]

  publicly_accessible = false
  multi_az            = false
  storage_encrypted   = true

  tags = {
    Name = "redmine-db"
  }
}
