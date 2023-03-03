resource "cloudflare_argo_tunnel" "lily_k8s" {
  account_id = cloudflare_account.account.id
  name       = "Lily (k8s)"
  secret     = ""

  lifecycle {
    ignore_changes = [secret]
  }
}
