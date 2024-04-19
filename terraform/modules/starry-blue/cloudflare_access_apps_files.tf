# resource "cloudflare_access_application" "files" {
#   account_id           = cloudflare_account.account.id
#   name                 = cloudflare_record.cname_files.hostname
#   domain               = cloudflare_record.cname_files.hostname
#   type                 = "bookmark"
#   logo_url             = "https://github.com/filebrowser/logo/raw/master/icon.svg"
#   app_launcher_visible = true
# }
