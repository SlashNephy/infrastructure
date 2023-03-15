resource "cloudflare_pages_project" "omikuji" {
  account_id        = cloudflare_account.account.id
  name              = "anime-omikuji"
  production_branch = "master"

  build_config {
    build_command   = "yarn build"
    destination_dir = "dist"
    // web_analytics_tag   = "aefe5bfc65454cc7afcb53f8b2018fa1"
    // web_analytics_token = "6f309eaea489422f9b55484613aa6cad"
  }

  deployment_configs {
    preview {
      compatibility_date    = "2023-02-21"
      environment_variables = {
        "NODE_VERSION" = "18"
      }
    }

    production {
      compatibility_date    = "2023-02-21"
      environment_variables = {
        "NODE_VERSION" = "18"
      }
    }
  }

  source {
    type = "github"

    config {
      deployments_enabled           = true
      production_deployment_enabled = true
      owner                         = "SlashNephy"
      repo_name                     = "anime-omikuji"
      production_branch             = "master"
      pr_comments_enabled           = true
      preview_branch_includes       = [
        "*",
      ]
      preview_branch_excludes = [
        "renovate/*"
      ]
      preview_deployment_setting = "custom"
    }
  }
}

resource "cloudflare_pages_domain" "omikuji" {
  account_id   = cloudflare_account.account.id
  project_name = "anime-omikuji"
  domain       = cloudflare_record.cname_omikuji.hostname
}
