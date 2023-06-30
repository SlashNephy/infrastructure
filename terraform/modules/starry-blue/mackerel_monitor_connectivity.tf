resource "mackerel_monitor" "connectivity" {
  name = "疎通できない状態になっている"

  connectivity {
    scopes = ["Production:Server"]
  }
}
