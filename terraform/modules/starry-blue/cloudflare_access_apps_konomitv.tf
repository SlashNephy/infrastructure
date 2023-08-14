resource "cloudflare_access_application" "konomitv" {
  account_id                 = cloudflare_account.account.id
  name                       = "KonomiTV"
  domain                     = cloudflare_record.cname_konomitv.hostname
  type                       = "self_hosted"
  logo_url                   = "https://pbs.twimg.com/profile_images/1592266272993333250/xNKHVQO9_400x400.jpg"
  app_launcher_visible       = true
  allowed_idps               = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity  = true
  session_duration           = "168h"
  same_site_cookie_attribute = "lax"
  http_only_cookie_attribute = true
  enable_binding_cookie      = false
}

resource "cloudflare_access_policy" "konomitv" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.konomitv.id
  name           = "private-dtv"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private_dtv.id]
  }
}
