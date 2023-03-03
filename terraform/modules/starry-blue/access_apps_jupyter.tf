resource "cloudflare_access_application" "jupyter" {
  account_id                = cloudflare_account.account.id
  name                      = "Jupyter"
  domain                    = "jupyter.starry.blue"
  type                      = "self_hosted"
  logo_url                  = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/1200px-Jupyter_logo.svg.png"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "jupyter" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.jupyter.id
  name           = "private"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization_private.id]
  }
}
