# output
output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_a_id" {
  description = "ID du subnet public (AZ A)"
  value       = aws_subnet.public_a.id
}

output "private_subnet_a_id" {
  description = "ID du subnet privé (AZ A)"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "ID du subnet privé (AZ B)"
  value       = aws_subnet.private_b.id
}
output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the Bastion host"
  value       = aws_instance.bastion.private_ip
}

output "proxy_public_ip" {
  description = "Public IP of the Reverse Proxy"
  value       = aws_instance.proxy.public_ip
}

output "proxy_private_ip" {
  description = "Private IP of the Reverse Proxy"
  value       = aws_instance.proxy.private_ip
}

output "manager_private_ip" {
  description = "Private IP of the App Manager"
  value       = aws_instance.manager.private_ip
}

output "worker1_private_ip" {
  description = "Private IP of the App Worker 1"
  value       = aws_instance.worker1.private_ip
}

output "worker2_private_ip" {
  description = "Private IP of the App Worker 2"
  value       = aws_instance.worker2.private_ip
}

output "monitoring_private_ip" {
  description = "Private IP of the Monitoring server"
  value       = aws_instance.monitoring.private_ip
}
 
# outputd_db

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.redmine_db.address
}

output "rds_name" {
  description = "RDS database name"
  value       = aws_db_instance.redmine_db.db_name
}
