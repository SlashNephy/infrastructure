resource "cloudflare_pages_project" "docs" {
  account_id        = cloudflare_account.account.id
  name              = cloudflare_record.cname_docs.hostname
  production_branch = "master"

  build_config {
    build_command   = "yarn build"
    destination_dir = "build"
    // web_analytics_tag   = "aefe5bfc65454cc7afcb53f8b2018fa1"
    // web_analytics_token = "6f309eaea489422f9b55484613aa6cad"
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
  project_name = cloudflare_record.cname_docs.hostname
  domain       = cloudflare_record.cname_docs.hostname
}
