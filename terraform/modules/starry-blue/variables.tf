locals {
  webmaster_email_address  = "webmaster@starry.blue"
  github_organization_name = "StarryBlueSky"
}

variable "onepassword_service_account_token" {
  type = string
}

variable "cloudflare_api_token" {
  type = string
}

variable "mackerel_api_key" {
  type = string
}
