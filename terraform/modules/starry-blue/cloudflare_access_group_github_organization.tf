resource "cloudflare_access_group" "github_organization" {
  account_id = cloudflare_account.account.id
  name       = "GitHub Organization"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
    }

    service_token = [cloudflare_access_service_token.mackerel.id]
  }

  require {
    geo = ["JP"]
  }
}
