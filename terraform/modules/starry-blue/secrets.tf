data "onepassword_vault" "terraform" {
  uuid = "7y5v3rmq4dpwnk2bgbm7vig3su"
}

data "onepassword_item" "github_oauth_client" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "47j2n5ecdeulpja5mh5hud7eom"
}

data "onepassword_item" "general_slack_webhook_url" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "y7x5qzuvf4bkqw6g7uosnqwfw4"
}

data "onepassword_item" "dtv_slack_webhook_url" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "uwlqjbuowntpe2njzvk3xk6m2m"
}
