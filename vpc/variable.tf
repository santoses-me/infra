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

variable "mysql_db_restore_from_snapshot" {
  description = "When true, restore cluster from snapshot_identifier"
  type        = bool
  default     = false
}

variable "mysql_db_snapshot_identifier" {
  description = "Manual/final snapshot ID to restore from"
  type        = string
  default     = ""
}

variable "mysql_db_skip_final_snapshot" {
  description = "Skip final snapshot on destroy (dev only)"
  type        = bool
  default     = false
}

variable "bastion_name" {
  type = string
  default = "santoses-vadev-bastion"
}

