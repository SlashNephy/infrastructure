resource "cloudflare_access_application" "navidrome" {
  account_id = cloudflare_account.account.id
  name       = "Navidrome"
  domain     = cloudflare_record.cname_navidrome.hostname
  type       = "self_hosted"
  // logo_url                   = "https://pbs.twimg.com/profile_images/1592266272993333250/xNKHVQO9_400x400.jpg"
  app_launcher_visible       = true
  allowed_idps               = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity  = true
  session_duration           = "168h"
  same_site_cookie_attribute = "lax"
  http_only_cookie_attribute = true
  enable_binding_cookie      = false
  service_auth_401_redirect  = true
}

resource "cloudflare_access_policy" "navidrome" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.navidrome.id
  name           = "private"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private.id]
  }
}

resource "cloudflare_access_policy" "navidrome_mackerel" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.navidrome.id
  name           = "Mackerel"
  decision       = "non_identity"
  precedence     = 2

  include {
    group = [cloudflare_access_group.mackerel.id]
  }
}
