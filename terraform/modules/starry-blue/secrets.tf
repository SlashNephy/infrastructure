data "onepassword_vault" "terraform" {
  uuid = "7y5v3rmq4dpwnk2bgbm7vig3su"
}

data "onepassword_item" "github_oauth_client" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "47j2n5ecdeulpja5mh5hud7eom"
}

data "onepassword_item" "email_routing_catch_all_address" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "gfkmkrndebubvjkdn34zx6fsxy"
}

data "onepassword_item" "general_slack_webhook_url" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "y7x5qzuvf4bkqw6g7uosnqwfw4"
}

data "onepassword_item" "dtv_slack_webhook_url" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "uwlqjbuowntpe2njzvk3xk6m2m"
}

data "onepassword_item" "external-manganese_credential" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "fuc6xybsk6suzz54norqfi3xyq"
}

data "onepassword_item" "external-rhodium_credential" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "cofdojufkusps5ftoz6rj3ucgu"
}

data "onepassword_item" "external-uranium_credential" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "umuxhtvvkl6ae7llrat6x3jg5e"
}

data "onepassword_item" "external-selenium_credential" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "4uc6ztmuv6drw4xe37nobd7aqu"
}
