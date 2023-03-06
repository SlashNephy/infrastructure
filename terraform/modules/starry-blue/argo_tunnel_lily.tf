resource "cloudflare_argo_tunnel" "lily" {
  account_id = cloudflare_account.account.id
  name       = "Lily"
  secret     = ""

  lifecycle {
    ignore_changes = [secret]
  }
}

resource "cloudflare_tunnel_config" "lily" {
  account_id = cloudflare_account.account.id
  tunnel_id  = cloudflare_argo_tunnel.lily.id

  config {
    ingress_rule {
      hostname = cloudflare_record.cname_ssh.hostname
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

resource "cloudflare_tunnel_route" "lily" {
  account_id = cloudflare_account.account.id
  tunnel_id  = cloudflare_argo_tunnel.lily.id
  network    = var.lily_network
}
