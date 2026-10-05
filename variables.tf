variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "cloud-resume"
}

variable "domain_name" {
  description = "Primary domain name for the portfolio site"
  type        = string
  default     = "ron-mercier101.com"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}
