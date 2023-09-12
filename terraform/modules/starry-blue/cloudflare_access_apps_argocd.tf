resource "cloudflare_access_application" "argocd" {
  account_id                 = cloudflare_account.account.id
  name                       = "Argo CD"
  domain                     = cloudflare_record.cname_argocd.hostname
  type                       = "self_hosted"
  logo_url                   = "https://cncf-branding.netlify.app/img/projects/argo/icon/color/argo-icon-color.png"
  app_launcher_visible       = true
  allowed_idps               = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity  = true
  session_duration           = "168h"
  same_site_cookie_attribute = "lax"
  http_only_cookie_attribute = true
  enable_binding_cookie      = false
  service_auth_401_redirect  = true
}

resource "cloudflare_access_policy" "argocd" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.argocd.id
  name           = "private-server-access"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private_server_access.id]
  }
}

resource "cloudflare_access_policy" "argocd_mackerel" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.argocd.id
  name           = "Mackerel"
  decision       = "non_identity"
  precedence     = 2

  include {
    group = [cloudflare_access_group.mackerel.id]
  }
}

resource "cloudflare_access_application" "argocd_webhook" {
  account_id                 = cloudflare_account.account.id
  name                       = "Argo CD (Webhook)"
  domain                     = "${cloudflare_record.cname_argocd.hostname}/api/webhook"
  type                       = "self_hosted"
  logo_url                   = "https://cncf-branding.netlify.app/img/projects/argo/icon/color/argo-icon-color.png"
  app_launcher_visible       = false
  same_site_cookie_attribute = "lax"
  http_only_cookie_attribute = true
  enable_binding_cookie      = false
}

resource "cloudflare_access_policy" "argocd_webhook" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.argocd_webhook.id
  name           = "everyone"
  decision       = "bypass"
  precedence     = 1

  include {
    group = [cloudflare_access_group.everyone.id]
  }
}
