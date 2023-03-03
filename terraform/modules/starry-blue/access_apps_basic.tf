resource "cloudflare_access_application" "token" {
  account_id                = cloudflare_account.account.id
  name                      = "atmos-token-distributor"
  domain                    = cloudflare_record.cname_basic.hostname
  type                      = "self_hosted"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "token" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.token.id
  name           = "private-dtv"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private_dtv.id]
  }
}
