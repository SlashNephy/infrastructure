#!/usr/bin/env ash

set -e

apk add zstd
tar -acpf /dist/volumes.zst /src || true
rclone copy /dist horoscope:Backup --config /rclone.conf
rm -f /dist/volumes.zst
