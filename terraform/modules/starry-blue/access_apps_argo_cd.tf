resource "cloudflare_access_application" "argo_cd" {
  account_id                = local.cloudflare_account_id
  name                      = "Argo CD"
  domain                    = "argocd.starry.blue"
  type                      = "self_hosted"
  logo_url                  = "https://cncf-branding.netlify.app/img/projects/argo/icon/color/argo-icon-color.png"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "argo_cd" {
  account_id     = local.cloudflare_account_id
  application_id = cloudflare_access_application.argo_cd.id
  name           = "private-server-access"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization_private_server_access.id]
  }
}

resource "cloudflare_access_application" "argo_cd_webhook" {
  account_id           = local.cloudflare_account_id
  name                 = "Argo CD (Webhook)"
  domain               = "argocd.starry.blue/api/webhook"
  type                 = "self_hosted"
  logo_url             = "https://cncf-branding.netlify.app/img/projects/argo/icon/color/argo-icon-color.png"
  app_launcher_visible = false
}

resource "cloudflare_access_policy" "argo_cd_webhook" {
  account_id     = local.cloudflare_account_id
  application_id = cloudflare_access_application.argo_cd.id
  name           = "everyone"
  decision       = "bypass"
  precedence     = 0

  include {
    group = [cloudflare_access_group.everyone.id]
  }
}
