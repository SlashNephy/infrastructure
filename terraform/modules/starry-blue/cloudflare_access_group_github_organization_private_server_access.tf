resource "cloudflare_access_group" "github_organization_private_server_access" {
  account_id = cloudflare_account.account.id
  name       = "GitHub Organization (private-server-access)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private-server-access"]
    }

    service_token = [cloudflare_access_service_token.mackerel.id]
  }

  require {
    geo = ["JP"]
  }
}
