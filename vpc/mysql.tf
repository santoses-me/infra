module "aurora_mysql_v2" {
  count  = var.mysql_db_enable ? 1 : 0
  source = "terraform-aws-modules/rds-aurora/aws"

  name              = "${var.name}-mysqlv2"
  engine            = "aurora-mysql"
  engine_mode       = "provisioned"
  engine_version    = "8.0"
  storage_encrypted = true
  master_username   = "root"

  snapshot_identifier = var.mysql_db_restore_from_snapshot ? var.mysql_db_snapshot_identifier : null

  vpc_id                = module.vpc.vpc_id
  db_subnet_group_name  = module.vpc.database_subnet_group_name
  create_security_group = false

  monitoring_interval = 60

  apply_immediately = true

  # Snapshot behavior on destroy
  skip_final_snapshot       = var.mysql_db_skip_final_snapshot
  final_snapshot_identifier = var.mysql_db_skip_final_snapshot ? null : "${var.name}-final-${random_id.snapshot_suffix.hex}"

  serverlessv2_scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 0.5
  }

  instance_class = "db.serverless"
  instances = {
    one = {}
  }

  tags = local.tags
}

# Unique suffix for final snapshot name (so destroy never fails on duplicate)
resource "random_id" "snapshot_suffix" {
  byte_length = 3
}