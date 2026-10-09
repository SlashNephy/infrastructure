#!/bin/ash
# CiliumCIDRGroup の externalCIDRs を取得元の最新の一覧に置き換える。
# 使い方: update.sh <CiliumCIDRGroup の名前>
#
# この一覧は Traefik の ingress の許可リストとして使う。取得の異常で一覧が縮むと正規の利用者を締め出すので、
# 件数の下限と削除数の上限を超える変更は適用せずに失敗させ、前回の一覧を残す
set -euo pipefail

name=$1

case "$name" in
  jp-ipv6)
    fetch() {
      curl -fsS --retry 3 https://ftp.apnic.net/stats/apnic/delegated-apnic-latest |
        awk -F'|' '$2 == "JP" && $3 == "ipv6" { print $4 "/" $5 }'
    }
    # 2026-10 時点で 766 件
    min_count=500
    # 割り当ての返却はまれなので、まとまった削除は取得の異常とみなす
    max_removed=20
    ;;
  cloudflare)
    fetch() {
      # どちらも末尾に改行が無い
      curl -fsS --retry 3 https://www.cloudflare.com/ips-v4
      echo
      curl -fsS --retry 3 https://www.cloudflare.com/ips-v6
      echo
    }
    # 2026-10 時点で 22 件
    min_count=15
    # 消えたレンジから届くプロキシ経由のアクセスが全て落ちるので、削除は手で確かめてから行う
    max_removed=0
    ;;
  *)
    echo "unknown CiliumCIDRGroup: $name" >&2
    exit 1
    ;;
esac

work=$(mktemp -d)

# 一致する行が無いと grep が失敗するので、空の一覧はここで弾かれる
fetch | grep -E '^[0-9A-Fa-f:.]+/[0-9]+$' | sort -u > "$work/new"
kubectl get ciliumcidrgroup "$name" -o jsonpath='{range .spec.externalCIDRs[*]}{@}{"\n"}{end}' | sort -u > "$work/current"

count=$(wc -l < "$work/new")
comm -13 "$work/current" "$work/new" > "$work/added"
comm -23 "$work/current" "$work/new" > "$work/removed"
added=$(wc -l < "$work/added")
removed=$(wc -l < "$work/removed")
echo "$name: $count CIDRs (+$added, -$removed)"
sed 's/^/+ /' "$work/added"
sed 's/^/- /' "$work/removed"

if [ "$count" -lt "$min_count" ]; then
  echo "refusing to update $name: $count CIDRs is below the minimum of $min_count" >&2
  exit 1
fi
if [ "$removed" -gt "$max_removed" ]; then
  echo "refusing to update $name: $removed CIDRs would be removed (limit: $max_removed)" >&2
  exit 1
fi
if [ "$added" -eq 0 ] && [ "$removed" -eq 0 ]; then
  exit 0
fi

awk 'BEGIN { printf "{\"spec\":{\"externalCIDRs\":[" } { printf "%s\"%s\"", (NR > 1 ? "," : ""), $0 } END { print "]}}" }' "$work/new" > "$work/patch.json"
kubectl patch ciliumcidrgroup "$name" --type=merge --patch-file "$work/patch.json"
