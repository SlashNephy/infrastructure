resource "cloudflare_access_application" "ssh_bbc" {
  account_id                = cloudflare_account.account.id
  name                      = "SSH (bbc)"
  domain                    = cloudflare_record.cname_bbc_ssh.hostname
  type                      = "ssh"
  logo_url                  = "https://github.com/openssh.png"
  app_launcher_visible      = true
  allowed_idps              = [cloudflare_access_identity_provider.github_oauth.id]
  auto_redirect_to_identity = true
  session_duration          = "168h"
  skip_interstitial         = true
}

resource "cloudflare_access_policy" "ssh_bbc" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.ssh_bbc.id
  name           = "private-server-access"
  decision       = "allow"
  precedence     = 1

  include {
    group = [cloudflare_access_group.github_organization_private_server_access.id]
  }
}

resource "cloudflare_access_ca_certificate" "ssh_bbc" {
  account_id     = cloudflare_account.account.id
  application_id = cloudflare_access_application.ssh_bbc.id
}
