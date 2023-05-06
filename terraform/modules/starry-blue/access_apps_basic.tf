resource "cloudflare_access_application" "basic" {
  account_id                 = cloudflare_account.account.id
  name                       = "htpasswd-dashboard"
  domain                     = cloudflare_record.cname_basic.hostname
  type                       = "self_hosted"
  app_launcher_visible       = true
  allowed_idps               = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity  = true
  session_duration           = "24h"
  same_site_cookie_attribute = "lax"
  http_only_cookie_attribute = true
  enable_binding_cookie      = false
}

resource "cloudflare_access_policy" "basic" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.basic.id
  name           = "private-dtv"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private_dtv.id]
  }
}
