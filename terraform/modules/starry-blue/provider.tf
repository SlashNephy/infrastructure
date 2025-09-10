terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.52.4"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.6.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
