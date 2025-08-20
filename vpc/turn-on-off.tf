variable "enable_nat" {
  type    = bool
  default = true
}

variable "mysql_db_enable" {
  description = "Create/destroy Aurora (snapshot on destroy when skip_final_snapshot=false)"
  type        = bool
  default     = true
}