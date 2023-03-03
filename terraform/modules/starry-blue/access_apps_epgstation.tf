resource "cloudflare_access_application" "epgstation" {
  account_id                = cloudflare_account.account.id
  name                      = "EPGStation"
  domain                    = cloudflare_record.cname_epgstation.hostname
  type                      = "self_hosted"
  logo_url                  = "https://pbs.twimg.com/profile_images/908684482508496896/rn5hvXpz_400x400.jpg"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "epgstation" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.epgstation.id
  name           = "private-dtv"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private_dtv.id]
  }
}
