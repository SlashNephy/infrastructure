resource "cloudflare_access_application" "konomitv" {
  account_id                = local.cloudflare_account_id
  name                      = "KonomiTV"
  domain                    = "konomitv.starry.blue"
  type                      = "self_hosted"
  logo_url                  = "https://pbs.twimg.com/profile_images/1592266272993333250/xNKHVQO9_400x400.jpg"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "konomitv" {
  account_id     = local.cloudflare_account_id
  application_id = cloudflare_access_application.konomitv.id
  name           = "private-dtv"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization_private_dtv.id]
  }
}
