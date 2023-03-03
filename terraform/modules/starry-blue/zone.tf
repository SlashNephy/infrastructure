resource "cloudflare_zone" "zone" {
  account_id = cloudflare_account.account.id
  zone       = "starry.blue"
}
