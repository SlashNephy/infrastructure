locals {
  webmaster_email_address  = "webmaster@starry.blue"
  github_organization_name = "StarryBlueSky"
  github_oauth_client_id   = "7540ca81583910ac1e6f"
}

variable "cloudflare_api_token" {
  type = string
}

variable "github_oauth_client_secret" {
  type = string
}

variable "email_routing_catch_all_address" {
  type = string
}

variable "mackerel_api_key" {
  type = string
}

variable "cloudflare_access_client_id" {
  type = string
}

variable "cloudflare_access_client_secret" {
  type = string
}

variable "basic_credentials" {
  type = map(object({
    user     = string
    password = string
  }))
}

variable "external_urls" {
  type = map(object({
    url      = string
    user     = string
    password = string
  }))
}
