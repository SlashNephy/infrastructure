resource "cloudflare_access_application" "cilium" {
  account_id                 = cloudflare_account.account.id
  name                       = "Cilium (Hubble UI)"
  domain                     = cloudflare_record.cname_cilium.hostname
  type                       = "self_hosted"
  logo_url                   = "https://github.com/cilium.png"
  app_launcher_visible       = true
  allowed_idps               = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity  = true
  session_duration           = "168h"
  same_site_cookie_attribute = "lax"
  http_only_cookie_attribute = true
  enable_binding_cookie      = false
  service_auth_401_redirect  = true
}

resource "cloudflare_access_policy" "cilium" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.cilium.id
  name           = "private-server-access"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private_server_access.id]
  }
}

resource "cloudflare_access_policy" "cilium_mackerel" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.cilium.id
  name           = "Mackerel"
  decision       = "non_identity"
  precedence     = 2

  include {
    group = [cloudflare_access_group.mackerel.id]
  }
}
