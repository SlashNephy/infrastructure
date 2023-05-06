resource "cloudflare_tunnel" "bbc" {
  account_id = cloudflare_account.account.id
  name       = "bbc"
  secret     = ""

  lifecycle {
    ignore_changes = [secret]
  }
}

resource "cloudflare_tunnel_config" "bbc" {
  account_id = cloudflare_account.account.id
  tunnel_id  = cloudflare_tunnel.bbc.id

  config {
    ingress_rule {
      hostname = cloudflare_record.cname_bbc.hostname
      service  = "http://localhost:30080"
    }

    ingress_rule {
      hostname = cloudflare_record.cname_bbc_basic.hostname
      service  = "http://localhost:33000"
    }

    ingress_rule {
      hostname = cloudflare_record.cname_bbc_ssh.hostname
      service  = "ssh://localhost:22"
    }

    ingress_rule {
      service = "http_status:418"
    }

    warp_routing {
      enabled = true
    }
  }
}

resource "cloudflare_tunnel_route" "bbc" {
  account_id = cloudflare_account.account.id
  tunnel_id  = cloudflare_tunnel.bbc.id
  network    = "192.168.11.0/24"
}
