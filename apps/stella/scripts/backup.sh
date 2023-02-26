#!/usr/bin/env bash

mongoexport \
  -h db \
  -u $MONGODB_USER \
  -p $MONGODB_PASSWORD \
  --authenticationDatabase=admin \
  -d stella \
  -c Pic \
  --jsonArray \
  --jsonFormat=canonical \
  --quiet | jq > /backup/PicTagReplace.json
