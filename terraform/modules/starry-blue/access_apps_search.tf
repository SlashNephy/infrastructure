resource "cloudflare_access_application" "search" {
  account_id                = local.cloudflare_account_id
  name                      = "ksearch"
  domain                    = "search.starry.blue"
  type                      = "self_hosted"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "search" {
  account_id     = local.cloudflare_account_id
  application_id = cloudflare_access_application.search.id
  name           = "org"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization.id]
  }
}
