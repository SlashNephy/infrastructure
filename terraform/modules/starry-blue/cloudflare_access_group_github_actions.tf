resource "cloudflare_access_group" "github_actions" {
  account_id = cloudflare_account.account.id
  name       = "GitHub Actions"

  include {
    service_token = [cloudflare_access_service_token.github_actions.id]
  }
}
