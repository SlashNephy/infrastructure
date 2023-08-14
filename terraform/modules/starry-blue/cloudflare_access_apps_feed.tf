resource "cloudflare_access_application" "feed" {
  account_id                 = cloudflare_account.account.id
  name                       = "Tiny Tiny RSS"
  domain                     = cloudflare_record.cname_feed.hostname
  type                       = "self_hosted"
  logo_url                   = "https://play-lh.googleusercontent.com/Y0uoeTTAr3E58oLMN2uTY9t-7IsyKwj_xrL6sdD737bbNlnGcu1D9TNlvwiyC2pYr04"
  app_launcher_visible       = true
  allowed_idps               = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity  = true
  session_duration           = "168h"
  same_site_cookie_attribute = "lax"
  http_only_cookie_attribute = true
  enable_binding_cookie      = false
}

resource "cloudflare_access_policy" "feed" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.feed.id
  name           = "private"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private.id]
  }
}
