resource "cloudflare_teams_account" "starry_blue_sky" {
  account_id           = cloudflare_account.account.id
  activity_log_enabled = true

  logging {
    redact_pii = true
    settings_by_rule_type {
      dns {
        log_all    = true
        log_blocks = true
      }
      http {
        log_all    = true
        log_blocks = true
      }
      l4 {
        log_all    = true
        log_blocks = true
      }
    }
  }

  fips {
    tls = true
  }

  proxy {
    tcp = true
    udp = false
  }

  antivirus {
    enabled_download_phase = true
    enabled_upload_phase   = false
    fail_closed            = false
  }
}
