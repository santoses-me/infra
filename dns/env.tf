locals {
  stage  = terraform.workspace
  region = local.context_variables[terraform.workspace]["region"]
  domain = "${terraform.workspace}.${local.context_variables[terraform.workspace]["domain"]}"

  context_variables = {
    vadev = {
      region = "us-east-1"
      domain = "santoses.me"
    }
  }
  tags = {
    env        = terraform.workspace
    managed_by = "terraform"
    repo       = "infra"
  }
}




