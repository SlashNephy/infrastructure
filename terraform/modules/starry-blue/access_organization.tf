resource "cloudflare_access_organization" "starry_blue_sky" {
  account_id                         = local.cloudflare_account_id
  name                               = "@StarryBlueSky"
  auth_domain                        = "starrybluesky.cloudflareaccess.com"
  is_ui_read_only                    = true
  user_seat_expiration_inactive_time = "720h"

  login_design {
    background_color = "#e6eef3"
    text_color       = "#000000"
    logo_path        = "https://github.com/StarryBlueSky.png"
    header_text      = "続行するにはサインインしてください。"
    footer_text      = "このアプリケーションは Cloudflare Access によって保護されています。"
  }
}
