resource "cloudflare_access_identity_provider" "discord" {
  account_id = cloudflare_account.account.id
  name       = "Discord"
  type       = "oidc"

  config {
    client_id     = data.onepassword_item.discord_oauth_client.username
    client_secret = data.onepassword_item.discord_oauth_client.password
    auth_url      = "https://discord-oidc.starrybluesky.workers.dev/authorize/guilds"
    token_url     = "https://discord-oidc.starrybluesky.workers.dev/token"
    certs_url     = "https://discord-oidc.starrybluesky.workers.dev/jwks.json"
    pkce_enabled  = true
    claims        = ["id", "preferred_username", "guilds"]
  }

  depends_on = [data.onepassword_item.discord_oauth_client]
}
