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

variable "general_slack_webhook_url" {
  type = string
}

variable "dtv_slack_webhook_url" {
  type = string
}
