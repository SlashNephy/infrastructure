resource "cloudflare_notification_policy" "expiring_service_token_alert" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "expiring_service_token_alert"
  name       = "Expiring Access Service Token Alert"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "dos_attack_l7" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "dos_attack_l7"
  name       = "HTTP DDoS Attack Alert"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "pages_event_alert" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "pages_event_alert"
  name       = "Pages Project Updates"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }

  filters {
    environment = ["ENVIRONMENT_PRODUCTION"]
    event       = ["EVENT_DEPLOYMENT_FAILED"]
    project_id  = [
      "07c48fd8-39c7-436e-a579-bf674f402a44",
      "1084a83a-fd3f-41b3-9a25-acf7fa8a1108",
      "5677980c-e26f-4f57-821d-351151c98b2b",
      "58a11813-e318-448a-9e1e-683574417039",
      "7df1ccc1-971e-49a4-a55e-6c0c29fd996a",
      "b76e433a-8ac6-413e-84c2-cb4cf79218f5",
      "cbf48d47-4863-4b09-8e6d-13c72fd5f5f3",
      "f1355289-5f0e-41cf-90b7-cade667e91ec",
    ]
  }
}

resource "cloudflare_notification_policy" "real_origin_monitoring" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "real_origin_monitoring"
  name       = "Passive Origin Monitoring"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "access_custom_certificate_expiration_type" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "access_custom_certificate_expiration_type"
  name       = "Access mTLS Certificate Expiration Alert"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "hostname_aop_custom_certificate_expiration_type" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "hostname_aop_custom_certificate_expiration_type"
  name       = "Hostname-level Authenticated Origin Pulls Certificate Expiration Alert"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "universal_ssl_event_type" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "universal_ssl_event_type"
  name       = "Universal SSL Alert"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "block_notification_review_rejected" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "block_notification_review_rejected"
  name       = "Trust and Safety Blocks: Block Review Rejection"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "block_notification_new_block" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "block_notification_new_block"
  name       = "Trust and Safety Blocks: New Blocks"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "block_notification_block_removed" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "block_notification_block_removed"
  name       = "Trust and Safety Blocks: Removed Blocks"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "tunnel_update_event" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "tunnel_update_event"
  name       = "Tunnel Creation or Deletion Event"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "tunnel_health_event" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "tunnel_health_event"
  name       = "Tunnel Health Alert"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}

resource "cloudflare_notification_policy" "web_analytics_metrics_update" {
  account_id = cloudflare_account.account.id

  enabled    = true
  alert_type = "web_analytics_metrics_update"
  name       = "Web Analytics: Weekly summary"

  webhooks_integration {
    id = cloudflare_notification_policy_webhooks.discord.id
  }
}
