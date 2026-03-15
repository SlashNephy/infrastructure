resource "cloudflare_zone" "zone" {
  account = {
    id = cloudflare_account.account.id
  }
  name = "starry.blue"
}
