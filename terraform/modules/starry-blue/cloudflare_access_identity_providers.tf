resource "cloudflare_access_identity_provider" "github_oauth" {
  account_id = cloudflare_account.account.id
  name       = "GitHub OAuth"
  type       = "github"

  config {
    client_id     = local.github_oauth_client_id
    client_secret = var.github_oauth_client_secret
  }
}
