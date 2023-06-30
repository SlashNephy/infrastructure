resource "cloudflare_access_group" "everyone" {
  account_id = cloudflare_account.account.id
  name       = "Everyone"

  include {
    everyone = true
  }
}
