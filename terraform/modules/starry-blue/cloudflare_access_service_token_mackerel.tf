resource "cloudflare_access_service_token" "mackerel" {
  account_id = cloudflare_account.account.id
  name       = "Mackerel"
  duration   = "forever"
}
