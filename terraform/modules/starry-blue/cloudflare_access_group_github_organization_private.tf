resource "cloudflare_access_group" "github_organization_private" {
  account_id = cloudflare_account.account.id
  name       = "GitHub Organization (private)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private"]
    }
  }

  require {
    geo = ["JP"]
  }
}
