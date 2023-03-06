resource "cloudflare_access_organization" "starry_blue_sky" {
  account_id      = cloudflare_account.account.id
  name            = "@StarryBlueSky"
  auth_domain     = "starrybluesky.cloudflareaccess.com"
  is_ui_read_only = false

  login_design {
    background_color = "#e6eef3"
    text_color       = "#000000"
    logo_path        = "https://github.com/StarryBlueSky.png"
    header_text      = "続行するにはサインインしてください。"
    footer_text      = "このアプリケーションは Cloudflare Access によって保護されています。"
  }
}
