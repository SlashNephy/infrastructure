FROM quay.io/curl/curl-base:8.23.0@sha256:221b2a46e34554e89455e44498b51324f9aa17805414da444c02bc18989fe351

# ベースイメージの更新を待たずに Alpine の修正版を取り込む
RUN apk upgrade --no-cache && apk add --no-cache jq

# ベースイメージの curl_user で動かす。runAsNonRoot で判定できるよう数値で指定する
USER 100:101
