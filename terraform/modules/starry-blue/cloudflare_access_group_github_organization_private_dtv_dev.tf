resource "cloudflare_access_group" "github_organization_private_dtv_dev" {
  account_id = cloudflare_account.account.id
  name       = "GitHub Organization (private-dtv-dev)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private-dtv-dev"]
    }
  }

  require {
    geo = ["JP"]
  }
}
