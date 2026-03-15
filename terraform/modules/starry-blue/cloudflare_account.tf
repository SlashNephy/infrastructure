resource "cloudflare_account" "account" {
  name = "StarryBlueSky"
  settings = {
    enforce_twofactor = true
  }
}
