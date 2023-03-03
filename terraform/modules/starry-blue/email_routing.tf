resource "cloudflare_email_routing_settings" "my_zone" {
  zone_id = cloudflare_zone.zone.id
  enabled = true
}

resource "cloudflare_email_routing_address" "catch_all_address" {
  account_id = cloudflare_account.account.id
  email      = var.email_routing_catch_all_address
}

resource "cloudflare_email_routing_catch_all" "catch_all" {
  zone_id = cloudflare_zone.zone.id
  name    = "Catch All"
  enabled = true

  matcher {
    type = "all"
  }

  action {
    type  = "forward"
    value = [cloudflare_email_routing_address.catch_all_address.email]
  }
}
