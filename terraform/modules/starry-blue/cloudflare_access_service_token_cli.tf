// XXX: これ何に使ってるんだっけ
resource "cloudflare_access_service_token" "cli" {
  account_id           = cloudflare_account.account.id
  name                 = "CLI"
  min_days_for_renewal = 30

  lifecycle {
    create_before_destroy = true
  }
}
