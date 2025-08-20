locals {
  stage  = terraform.workspace
  region = local.context_variables[local.stage]["region"]
  domain = "${local.stage}.${local.context_variables[local.stage]["domain"]}"

  context_variables = {
    vadev = {
      region = "us-east-1"
      domain = "santoses.me"
    }
  }

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Derive subnet CIDRs: 3 tiers per AZ (public, private, db)
  # We split /16 into /20s: 3 * az_count subnets
  # Adjust "newbits" if you want larger/smaller subnets.
  public_subnet_cidrs  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + length(local.azs))]
  db_subnet_cidrs      = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + length(local.azs) * 2)]

  tags = {
    env        = terraform.workspace
    managed_by = "terraform"
    repo       = "infra"
  }
}




