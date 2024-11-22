# cloudflare
variable "cf_workers_subdomain" {
  type = string
  description = "Cloudflare workers subdomain"
}

variable "cf_worker_name" {
  type = string
  description = "worker name"
  default = "idp-init-lambda"
}

/*
variable "connection_name" {
  type = string
  description = "social connection name"
  default = "cf-log"
}
*/


# auth0
variable "auth0_domain" {
  type = string
  description = "auth0 domain"
}

variable "auth0_tf_client_id" {
  type = string
  description = "Auth0 TF provider client_id"
}

variable "auth0_tf_client_secret" {
  type = string
  description = "Auth0 TF provider client_secret"
  sensitive = true
}

## AWS
variable "region" {
  default = "ap-southeast-2"
}
