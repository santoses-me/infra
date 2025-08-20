terraform {
  required_version = "1.12.2"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}