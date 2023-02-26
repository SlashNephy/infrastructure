#!/usr/bin/env ash

gh api \
  --method POST \
  -H "Accept: application/vnd.github.v3+json" \
  /repos/SlashNephy/TVTest-builder/releases \
  -f tag_name=`date -Idate`
