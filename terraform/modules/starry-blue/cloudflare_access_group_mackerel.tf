resource "cloudflare_access_group" "mackerel" {
  account_id = cloudflare_account.account.id
  name       = "Mackerel"

  include {
    service_token = [cloudflare_access_service_token.mackerel.id]
  }
}
