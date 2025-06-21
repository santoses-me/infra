resource "aws_cognito_user_pool" "user_pool" {
  name = "${local.stage}-cognito"

  auto_verified_attributes = [
    "email",
  ]

  username_attributes = [
    "email",
  ]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    from_email_address     = "\"Santoses\" <noreply@${local.domain}>"
    reply_to_email_address = "noreply@${local.domain}"
    source_arn             = aws_ses_email_identity.noreply.arn
    email_sending_account  = "DEVELOPER"
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    require_uppercase                = true
    temporary_password_validity_days = local.temp_password_valid_days
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 7
      max_length = 128
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "family_name"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "given_name"
    required                 = true

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  sms_authentication_message = "Your authentication code is {####}. "
  sms_verification_message   = "Your verification code is {####}. "

  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags
}