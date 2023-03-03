resource "cloudflare_account" "account" {
  name              = "StarryBlueSky"
  type              = "standard"
  enforce_twofactor = true
}
