terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.76"
    }
  }
}

provider "auth0" {
  domain        = var.auth0_domain
  client_id     = var.auth0_tf_client_id
  client_secret = var.auth0_tf_client_secret
}

provider "aws" {
  profile = "default"
  region = var.region
}