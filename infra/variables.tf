variable "aws_region" {
  type        = string
  description = "AWS region for deployment."
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "dev"
}

variable "external_api_url" {
  type        = string
  description = "External API URL consumed by the Glue job."
}

variable "rds_allocated_storage" {
  type        = number
  description = "Allocated storage for the RDS instance."
}

variable "rds_engine" {
  type        = string
  description = "RDS engine."
}

variable "rds_engine_version" {
  type        = string
  description = "RDS engine version."
}

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class."
}

variable "rds_db_name" {
  type        = string
  description = "Initial database name."
}

variable "rds_username" {
  type        = string
  description = "Master username for the RDS instance."
}

variable "rds_password" {
  type        = string
  description = "Master password for the RDS instance."
  sensitive   = true
}

variable "rds_backup_retention_period" {
  type        = number
  description = "Backup retention period for the RDS instance."
}