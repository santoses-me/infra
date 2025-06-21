provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    encrypt        = "true"
    bucket         = "santoses-vadev-tf"
    dynamodb_table = "santoses-vadev-tf-lock"
    region         = "us-east-1"
    key            = "oidc/terraform.tfstate"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}