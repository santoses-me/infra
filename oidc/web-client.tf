resource "aws_cognito_user_pool_client" "web_client" {
  name = "web"

  user_pool_id = aws_cognito_user_pool.user_pool.id

  callback_urls = local.callback_urls

  logout_urls = local.logout_urls

  allowed_oauth_flows = [
    "code",
  ]

  allowed_oauth_scopes = ["phone",
    "email",
    "openid",
    "profile",
    "aws.cognito.signin.user.admin",
  ]

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  write_attributes = [
    "given_name",
    "family_name",
    "email",
  ]

  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true

  lifecycle {
    prevent_destroy = true
  }

  id_token_validity      = 20
  access_token_validity  = 20
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}