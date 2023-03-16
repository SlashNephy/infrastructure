resource "cloudflare_record" "cname_root" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_apps" {
  zone_id = cloudflare_zone.zone.id
  name    = "apps"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_argocd" {
  zone_id = cloudflare_zone.zone.id
  name    = "argocd"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_asf" {
  zone_id = cloudflare_zone.zone.id
  name    = "asf"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_basic" {
  zone_id = cloudflare_zone.zone.id
  name    = "basic"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_bbc" {
  zone_id         = cloudflare_zone.zone.id
  name            = "bbc"
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}

resource "cloudflare_record" "cname_bbc_ssh" {
  zone_id         = cloudflare_zone.zone.id
  name            = "bbc-ssh"
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}

resource "cloudflare_record" "cname_blog" {
  zone_id = cloudflare_zone.zone.id
  name    = "blog"
  value   = "hatenablog.com"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "cname_code" {
  zone_id = cloudflare_zone.zone.id
  name    = "code"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_cydia" {
  zone_id = cloudflare_zone.zone.id
  name    = "cydia"
  value   = "slashnephy.github.io"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_docs" {
  zone_id = cloudflare_zone.zone.id
  name    = "docs"
  value   = "starrybluesky-documents.pages.dev"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_bing_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = "e16b9629e876c719a2f86c33b2a3194c"
  value   = "verify.bing.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_epgstation" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_epgstation_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation-api"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "cname_files" {
  zone_id = cloudflare_zone.zone.id
  name    = "files"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_jupyter" {
  zone_id = cloudflare_zone.zone.id
  name    = "jupyter"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_k8s" {
  zone_id = cloudflare_zone.zone.id
  name    = "k8s"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_konomitv" {
  zone_id = cloudflare_zone.zone.id
  name    = "konomitv"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_mirakurun" {
  zone_id = cloudflare_zone.zone.id
  name    = "mirakurun"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_mirakurun_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "mirakurun-api"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "cname_keel" {
  zone_id = cloudflare_zone.zone.id
  name    = "keel"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_owncast" {
  zone_id = cloudflare_zone.zone.id
  name    = "owncast"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_omikuji" {
  zone_id = cloudflare_zone.zone.id
  name    = "omikuji"
  value   = "anime-omikuji.pages.dev"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_rclone" {
  zone_id = cloudflare_zone.zone.id
  name    = "rclone"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_rustpad" {
  zone_id = cloudflare_zone.zone.id
  name    = "rustpad"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_search" {
  zone_id = cloudflare_zone.zone.id
  name    = "search"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_spica" {
  zone_id = cloudflare_zone.zone.id
  name    = "spica"
  value   = "slashnephy.github.io"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_ssh" {
  zone_id         = cloudflare_zone.zone.id
  name            = "ssh"
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}

resource "cloudflare_record" "cname_stella" {
  zone_id = cloudflare_zone.zone.id
  name    = "stella"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_traefik" {
  zone_id = cloudflare_zone.zone.id
  name    = "traefik"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_vj" {
  zone_id = cloudflare_zone.zone.id
  name    = "vj"
  value   = "muni-535.pages.dev"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_wol" {
  zone_id = cloudflare_zone.zone.id
  name    = "wol"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_whoami" {
  zone_id = cloudflare_zone.zone.id
  name    = "whoami"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_www" {
  zone_id = cloudflare_zone.zone.id
  name    = "www"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_inori" {
  zone_id = cloudflare_zone.zone.id
  name    = "inori"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_maaya" {
  zone_id = cloudflare_zone.zone.id
  name    = "maaya"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

// TODO: 廃止予定
resource "cloudflare_record" "cname_atmos" {
  zone_id = cloudflare_zone.zone.id
  name    = "atmos"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

// TODO: 廃止予定
resource "cloudflare_record" "cname_anemos" {
  zone_id = cloudflare_zone.zone.id
  name    = "anemos"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

// 互換性のために残す
resource "cloudflare_record" "cname_direct" {
  zone_id = cloudflare_zone.zone.id
  name    = "direct"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = false
}
