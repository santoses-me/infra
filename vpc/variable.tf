variable "name" {
  description = "Base name for the VPC and related resources"
  type        = string
  default     = "santoses-vadev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs to use"
  type        = number
  default     = 3
}

variable "enable_ipv6" {
  description = "Whether to allocate an IPv6 /56 from Amazon pool"
  type        = bool
  default     = false
}

variable "nat_per_az" {
  description = "Create one NAT per AZ for HA (true) or a single shared NAT (false)"
  type        = bool
  default     = false
}

variable "enable_nat" {
  type    = bool
  default = true
}
