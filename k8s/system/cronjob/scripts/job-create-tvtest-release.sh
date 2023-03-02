#!/usr/bin/env ash

apk add github-cli
gh api \
  --method POST \
  -H "Accept: application/vnd.github.v3+json" \
  /repos/SlashNephy/TVTest-builder/releases \
  -f tag_name=`date -Idate`
