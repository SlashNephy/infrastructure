resource "cloudflare_access_keys_configuration" "access_keys_configuration" {
  account_id                 = cloudflare_account.account.id
  key_rotation_interval_days = 180
}
