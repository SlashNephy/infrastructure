resource "cloudflare_access_group" "everyone" {
  account_id = local.cloudflare_account_id
  name       = "Everyone"

  include {
    everyone = true
  }
}

resource "cloudflare_access_group" "github_organization" {
  account_id = local.cloudflare_account_id
  name       = "GitHub Organization"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
    }
  }

  require {
    geo = ["JP"]
  }
}

resource "cloudflare_access_group" "github_organization_private" {
  account_id = local.cloudflare_account_id
  name       = "GitHub Organization (private)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private"]
    }
  }

  require {
    geo = ["JP"]
  }
}

resource "cloudflare_access_group" "github_organization_private_asf" {
  account_id = local.cloudflare_account_id
  name       = "GitHub Organization (private-asf)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private-asf"]
    }
  }

  require {
    geo = ["JP"]
  }
}

resource "cloudflare_access_group" "github_organization_private_discord_admin" {
  account_id = local.cloudflare_account_id
  name       = "GitHub Organization (private-discord-admin)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private-discord-admin"]
    }
  }

  require {
    geo = ["JP"]
  }
}

resource "cloudflare_access_group" "github_organization_private_dtv" {
  account_id = local.cloudflare_account_id
  name       = "GitHub Organization (private-dtv)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private-dtv"]
    }
  }

  require {
    geo = ["JP"]
  }
}

resource "cloudflare_access_group" "github_organization_private_dtv_dev" {
  account_id = local.cloudflare_account_id
  name       = "GitHub Organization (private-dtv-dev)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private-dtv-dev"]
    }
  }

  require {
    geo = ["JP"]
  }
}

resource "cloudflare_access_group" "github_organization_private_server_access" {
  account_id = local.cloudflare_account_id
  name       = "GitHub Organization (private-server-access)"

  include {
    github {
      identity_provider_id = cloudflare_access_identity_provider.github_oauth.id
      name                 = local.github_organization_name
      teams                = ["private-server-access"]
    }
  }

  require {
    geo = ["JP"]
  }
}
