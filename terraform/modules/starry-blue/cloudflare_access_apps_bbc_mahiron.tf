resource "cloudflare_access_application" "bbc_mahiron" {
  account_id                 = cloudflare_account.account.id
  name                       = "Mahiron (bbc)"
  domain                     = cloudflare_record.cname_bbc_mahiron.hostname
  type                       = "self_hosted"
  logo_url                   = "https://github.com/21S1298001/Mahiron/raw/main/src/ui/icon.svg"
  app_launcher_visible       = true
  allowed_idps               = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity  = true
  session_duration           = "168h"
  same_site_cookie_attribute = "lax"
  http_only_cookie_attribute = true
  enable_binding_cookie      = false
}

resource "cloudflare_access_policy" "bbc_mahiron" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.bbc_mahiron.id
  name           = "private-dtv"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private_dtv.id]
  }
}
