locals {
  discord_bakarasukun_group_id     = "58de6121-a42a-4eb2-b49c-0e7f321c6f6e"
  discord_starry_blue_sky_group_id = "5467b738-e840-4588-97b7-23e931ac7b65"
  discord_kaigen_group_id          = "c647b2f9-4720-4f50-86eb-0aaeb5d8b631"
}

// include ブロック内に OIDC Claims を記述することができない (2023/10/9)
// resource "cloudflare_access_group" "discord_bakarasukun" {
//   account_id = cloudflare_account.account.id
//   name       = "Discord (bakarasukun's server)"
//
//   include {
//     oidc {
//       claim_name           = "guilds"
//       claim_value          = "743176054058909696"
//       identity_provider_id = cloudflare_access_identity_provider.discord.id
//     }
//   }
//
//   require {
//     login_method = [cloudflare_access_identity_provider.discord.id]
//   }
// }
