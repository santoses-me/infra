locals {
  stage                    = terraform.workspace
  region                   = local.context_variables[local.stage]["region"]
  domain                   = "${local.stage}.${local.context_variables[local.stage]["domain"]}"
  temp_password_valid_days = local.context_variables[local.stage]["temp_password_valid_days"]
  callback_urls            = local.context_variables[local.stage]["callback_urls"]
  logout_urls              = local.context_variables[local.stage]["logout_urls"]

  context_variables = {
    vadev = {
      region                   = "us-east-1"
      domain                   = "santoses.me"
      temp_password_valid_days = 1
      callback_urls            = ["localhost:3200", "https://vadev.santoses.me"]
      logout_urls              = ["localhost:3200", "https://vadev.santoses.me"]
    }
  }

  tags = {
    env        = terraform.workspace
    managed_by = "terraform"
    repo       = "infra"
  }
}




