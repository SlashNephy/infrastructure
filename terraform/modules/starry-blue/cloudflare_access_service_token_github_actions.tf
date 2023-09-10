resource "cloudflare_access_service_token" "github_actions" {
  account_id = cloudflare_account.account.id
  name       = "GitHub Actions"
  duration   = "forever"
}
