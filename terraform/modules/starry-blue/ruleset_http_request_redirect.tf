resource "cloudflare_ruleset" "http_request_redirect" {
  account_id = local.cloudflare_account_id
  name       = "http_request_redirect"
  kind       = "root"
  phase      = "http_request_redirect"

  rules {
    enabled     = true
    description = "Voice Actors"
    action      = "redirect"
    action_parameters {
      from_list {
        name = "voice_actor"
        key  = "http.request.full_uri"
      }
    }

    expression = "http.request.full_uri in $voice_actor"
  }
}

resource "cloudflare_list" "voice_actor" {
  account_id = local.cloudflare_account_id
  name       = "voice_actor"
  kind       = "redirect"

  item {
    value {
      redirect {
        source_url  = "inori.starry.blue/"
        target_url  = "https://www.inoriminase.com/discography/?id=47"
        status_code = 302
      }
    }
  }

  item {
    value {
      redirect {
        source_url  = "maaya.starry.blue/"
        target_url  = "https://uchidamaaya.jp/"
        status_code = 302
      }
    }
  }
}
