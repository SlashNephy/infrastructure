resource "cloudflare_access_application" "wolweb" {
  account_id                = cloudflare_account.account.id
  name                      = "wolweb"
  domain                    = "wol.starry.blue"
  type                      = "self_hosted"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "wolweb" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.wolweb.id
  name           = "private"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization_private.id]
  }
}
