# =============================================================================
# FCK-NAT - Alternative économique aux NAT Gateways AWS
# =============================================================================

data "aws_ami" "fck_nat" {
  most_recent = true
  owners      = ["568608671756"] # fck-nat official

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role pour fck-nat
resource "aws_iam_role" "fck_nat" {
  name = "${var.project_name}-${var.environment}-fck-nat-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-fck-nat-role"
  }
}

resource "aws_iam_role_policy_attachment" "fck_nat_cloudwatch" {
  role       = aws_iam_role.fck_nat.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "fck_nat" {
  name = "${var.project_name}-${var.environment}-fck-nat-profile"
  role = aws_iam_role.fck_nat.name

  tags = {
    Name = "${var.project_name}-${var.environment}-fck-nat-profile"
  }
}

# Elastic IP pour fck-nat
resource "aws_eip" "fck_nat" {
  tags = {
    Name = "${var.project_name}-${var.environment}-fck-nat-eip"
  }

  depends_on = [aws_internet_gateway.gw]
}

# Instance fck-nat
resource "aws_instance" "fck_nat" {
  ami           = data.aws_ami.fck_nat.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_a.id

  # CRITIQUE : Désactiver la vérification source/destination
  source_dest_check = false

  vpc_security_group_ids = [aws_security_group.fck-nat-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.fck_nat.name
  monitoring             = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-fck-nat"
    Type = "fck-nat"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Association Elastic IP à fck-nat
resource "aws_eip_association" "fck_nat" {
  instance_id   = aws_instance.fck_nat.id
  allocation_id = aws_eip.fck_nat.id
}

# =============================================================================
# ROUTE - Une seule route car une seule route table privée
# =============================================================================

resource "aws_route" "private_to_fck_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.fck_nat.primary_network_interface_id
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "fck_nat_public_ip" {
  description = "IP publique de fck-nat"
  value       = aws_eip.fck_nat.public_ip
}

output "fck_nat_private_ip" {
  description = "IP privée de fck-nat"
  value       = aws_instance.fck_nat.private_ip
}

output "fck_nat_instance_id" {
  description = "Instance ID de fck-nat"
  value       = aws_instance.fck_nat.id
}