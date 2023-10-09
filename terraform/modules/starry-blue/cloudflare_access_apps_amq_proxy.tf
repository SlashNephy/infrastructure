resource "cloudflare_access_application" "amq_proxy" {
  account_id                 = cloudflare_account.account.id
  name                       = "amq-media-proxy"
  domain                     = cloudflare_record.cname_amq_proxy.hostname
  type                       = "self_hosted"
  app_launcher_visible       = false
  allowed_idps               = [cloudflare_access_identity_provider.discord.id]
  auto_redirect_to_identity  = true
  session_duration           = "730h"
  same_site_cookie_attribute = "none"
  http_only_cookie_attribute = true
  enable_binding_cookie      = true
  service_auth_401_redirect  = true
}

resource "cloudflare_access_policy" "amq_proxy" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.amq_proxy.id
  name           = "discord"
  decision       = "allow"
  precedence     = 1

  include {
    group = [local.discord_bakarasukun_group_id]
  }
}

resource "cloudflare_access_policy" "amq_proxy_mackerel" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.amq_proxy.id
  name           = "Mackerel"
  decision       = "non_identity"
  precedence     = 2

  include {
    group = [cloudflare_access_group.mackerel.id]
  }
}
