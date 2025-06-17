locals {
  stage  = terraform.workspace
  region = local.context_variables[terraform.workspace]["region"]

  context_variables = {
    vadev = {
      region = "us-east-1"
    }
  }
  tags = {
    env        = terraform.workspace
    managed_by = "terraform"
    repo       = "infra"
  }
}




