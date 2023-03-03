resource "cloudflare_access_application" "owncast" {
  account_id                = cloudflare_account.account.id
  name                      = "Owncast"
  domain                    = "owncast.starry.blue"
  type                      = "self_hosted"
  logo_url                  = "https://owncast.online/images/owncast-logo-1000x1000.png"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "owncast" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.owncast.id
  name           = "private"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization_private.id]
  }
}
