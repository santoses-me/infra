module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs              = local.azs
  public_subnets   = local.public_subnet_cidrs
  private_subnets  = local.private_subnet_cidrs
  database_subnets = local.db_subnet_cidrs

  enable_dns_support   = true
  enable_dns_hostnames = true

  # IPv6
  enable_ipv6            = var.enable_ipv6
  create_egress_only_igw = var.enable_ipv6

  # NAT per AZ for production HA (set nat_gateway_single = true for dev cost-savings)
  enable_nat_gateway     = var.enable_nat
  single_nat_gateway     = var.nat_per_az ? false : true
  one_nat_gateway_per_az = var.nat_per_az

  enable_vpn_gateway = false

  # Flow logs -> S3
  enable_flow_log                   = true
  flow_log_destination_type         = "s3"
  flow_log_destination_arn          = aws_s3_bucket.flow_logs.arn
  flow_log_max_aggregation_interval = 60

  # Useful default NACLs/SGs (module manages sane defaults). We'll keep NACLs default.
  manage_default_route_table     = true
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      # ipv6_cidr_blocks = var.enable_ipv6 ? ["::/0"] : []
    }
  ]

  # Tags
  tags                 = local.tags
  public_subnet_tags   = merge(local.tags, { tier = "public" })
  private_subnet_tags  = merge(local.tags, { tier = "app" })
  database_subnet_tags = merge(local.tags, { tier = "db" })
}

# SG for Interface VPC Endpoints – allow HTTPS from within the VPC
resource "aws_security_group" "endpoints" {
  name        = "${var.name}-endpoints-sg"
  description = "Allow HTTPS from VPC to Interface Endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "VPC internal HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    // todo if ever needed, provide correct value
    ipv6_cidr_blocks = var.enable_ipv6 ? [] : []
  }

  egress {
    description      = "All egress (to AWS services)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = var.enable_ipv6 ? ["::/0"] : []
  }

  tags = merge(local.tags, { name = "${var.name}-endpoints-sg" })
}

# Gateway Endpoints (S3/DynamoDB) – attach to private and db route tables
locals {
  rt_ids_for_gateway_endpoints = concat(
    module.vpc.private_route_table_ids,
    module.vpc.database_route_table_ids
  )
}

module "vpc_endpoints_gateway" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = local.rt_ids_for_gateway_endpoints
      tags            = merge(local.tags, { name = "${var.name}-s3-gw-endpoint" })
    }
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = local.rt_ids_for_gateway_endpoints
      tags            = merge(local.tags, { name = "${var.name}-dynamodb-gw-endpoint" })
    }
  }

  tags = local.tags
}

# Interface Endpoints – critical for private builds/logging/runtime without NAT:
# STS, ECR (api/dkr), CloudWatch Logs, SSM, SSMMessages, EC2Messages, Secrets Manager, KMS
# module "vpc_endpoints_interface" {
#   source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
#   version = "~> 5.0"
#
#   vpc_id             = module.vpc.vpc_id
#   security_group_ids = [aws_security_group.endpoints.id]
#   subnet_ids         = module.vpc.private_subnets
#
#   endpoints = {
#     sts            = { service = "sts" }
#     ecr_api        = { service = "ecr.api" }
#     ecr_dkr        = { service = "ecr.dkr" }
#     logs           = { service = "logs" }
#     ssm            = { service = "ssm" }
#     ssmmessages    = { service = "ssmmessages" }
#     ec2messages    = { service = "ec2messages" }
#     secretsmanager = { service = "secretsmanager" }
#     kms            = { service = "kms" }
#   }
#
#   tags = local.tags
# }

# Example SGs (optional starters)
# ALB -> App
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Public ALB inbound 80/443"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { role = "alb" })
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "App tier accepts from ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { role = "app" })
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "DB tier accepts from app tier"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "App to DB (5432 example for Postgres)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { role = "db" })
}