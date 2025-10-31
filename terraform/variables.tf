variable "vpc_cidr" {
  description = "CIDR du VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "DB user"
  type        = string
  sensitive   = true
}
variable "redmine_db_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}
variable "ssh_public_keys" {
  description = "Liste des clés SSH publiques"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Redmine-Project"
  type        = string
  default     = "Redmine-Project"
}

variable "environment" {
  description = "Environnement (staging, prod)"
  type        = string
  default     = "prod"
}

variable "availability_zones" {
  description = "Liste des Availability Zones"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "private_subnet_cidrs" {
  description = "CIDR des subnets privés"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}