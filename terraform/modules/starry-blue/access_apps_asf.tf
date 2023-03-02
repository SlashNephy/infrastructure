resource "cloudflare_access_application" "arch-steam-farm" {
  account_id           = local.cloudflare_account_id
  name                 = "ArchSteamFarm"
  domain               = "asf.starry.blue"
  type                 = "self_hosted"
  logo_url             = "https://raw.githubusercontent.com/JustArchiNET/ArchiSteamFarm/main/resources/ASF_184x184.png"
  app_launcher_visible = true
  allowed_idps         = [cloudflare_access_identity_provider.github_oauth.id]
  session_duration     = "24h"
}

resource "cloudflare_access_policy" "arch-steam-farm" {
  account_id     = local.cloudflare_account_id
  application_id = cloudflare_access_application.arch-steam-farm.id
  name           = "private-asf"
  decision       = "allow"
  precedence     = 0

  include {
    group = [cloudflare_access_group.github_organization_private_asf.id]
  }
}
