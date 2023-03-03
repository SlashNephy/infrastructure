locals {
  cloudflare_zone_id       = "dc3b4dce36437ddabcc6cdcc2d1019f0"
  cloudflare_account_id    = "acf825cc392e96dca126ee7e7f39e228"
  cloudflare_access_domain = "starrybluesky.cloudflareaccess.com"
  github_organization_name = "StarryBlueSky"
  github_oauth_client_id   = "7540ca81583910ac1e6f"
}

variable "cloudflare_api_token" {
  type = string
}

variable "github_oauth_client_secret" {
  type = string
}
