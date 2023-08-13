resource "cloudflare_access_identity_provider" "github_oauth" {
  account_id = cloudflare_account.account.id
  name       = "GitHub OAuth"
  type       = "github"

  config {
    client_id     = data.onepassword_item.github_oauth_client.username
    client_secret = data.onepassword_item.github_oauth_client.password
  }

  depends_on = [data.onepassword_item.github_oauth_client]
}
