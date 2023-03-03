resource "cloudflare_access_application" "files" {
  account_id           = cloudflare_account.account.id
  name                 = "files.starry.blue"
  domain               = "files.starry.blue"
  type                 = "bookmark"
  logo_url             = "https://raw.githubusercontent.com/svenstaro/miniserve/master/data/logo.svg"
  app_launcher_visible = true
}

resource "cloudflare_access_application" "files_mnt" {
  account_id                = cloudflare_account.account.id
  name                      = "files.starry.blue (/mnt)"
  domain                    = "files.starry.blue/mnt"
  type                      = "self_hosted"
  logo_url                  = "https://raw.githubusercontent.com/svenstaro/miniserve/master/data/logo.svg"
  app_launcher_visible      = false
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "24h"
}

resource "cloudflare_access_policy" "files_mnt" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.files_mnt.id
  name           = "private-dtv"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization_private_dtv.id]
  }
}
