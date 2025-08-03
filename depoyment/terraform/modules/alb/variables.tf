variable "alb_name" {
  description = "The name of the ALB."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the ALB will be created."
  type        = string
}

variable "subnet_ids" {
  description = "A list of public subnet IDs for the ALB."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to the ALB."
  type        = map(string)
}

variable "enable_alb_deletion" {
  description = "Enable deletion protection for the ALB."
  type        = bool
  default     = false
}

# SSL/TLS Certificate Variables
variable "domain_name" {
  description = "The primary domain name for the SSL certificate"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Additional domain names for the SSL certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "The Route53 hosted zone ID for DNS validation"
  type        = string
  default     = ""
}

variable "create_www_redirect" {
  description = "Whether to create a www subdomain redirect"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Whether to enable HTTPS with SSL certificate"
  type        = bool
  default     = false
}
