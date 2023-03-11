resource "cloudflare_pages_project" "docs" {
  account_id        = cloudflare_account.account.id
  name              = "starrybluesky-documents"
  production_branch = "master"

  build_config {
    build_command       = "yarn build"
    destination_dir     = "build"
    web_analytics_tag   = "80eebe11fd4a42168606b4a6dab3e3bb"
    web_analytics_token = "ae6c0a51759443fd88ff6ed4eaec8d18"
  }

  deployment_configs {
    preview {
      compatibility_date    = "2023-02-21"
      environment_variables = {
        "NODE_VERSION" = "16"
      }
    }

    production {
      compatibility_date    = "2023-02-21"
      environment_variables = {
        "NODE_VERSION" = "16"
      }
    }
  }

  source {
    type = "github"

    config {
      deployments_enabled           = true
      production_deployment_enabled = true
      owner                         = "StarryBlueSky"
      repo_name                     = "documents"
      production_branch             = "master"
      pr_comments_enabled           = true
      preview_deployment_setting    = "none"
    }
  }
}

resource "cloudflare_pages_domain" "docs" {
  account_id   = cloudflare_account.account.id
  project_name = "starrybluesky-documents"
  domain       = cloudflare_record.cname_docs.hostname
}
