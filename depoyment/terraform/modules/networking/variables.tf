# tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "public_subnets" {
  description = "A map of public subnet CIDR blocks."
  type = map(object({
    cidr_block = string
    az         = string
  }))

}


variable "private_subnets" {
  description = "A map of private subnet CIDR blocks."
  type = map(object({
    cidr_block = string
    az         = string
  }))

}

variable "vpc_cidr" {
  description = "cidr range for the VPC"
  type        = string
}
