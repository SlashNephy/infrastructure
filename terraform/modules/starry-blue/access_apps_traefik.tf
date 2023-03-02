resource "cloudflare_access_application" "traefik" {
  account_id                = local.cloudflare_account_id
  name                      = "traefik"
  domain                    = "traefik.starry.blue"
  type                      = "self_hosted"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "traefik" {
  account_id     = local.cloudflare_account_id
  application_id = cloudflare_access_application.traefik.id
  name           = "private-server-access"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization_private_server_access.id]
  }
}
