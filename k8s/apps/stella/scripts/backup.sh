#!/usr/bin/env bash

mongoexport \
  -h db \
  -u $MONGODB_USER \
  -p $MONGODB_PASSWORD \
  --authenticationDatabase=admin \
  -d stella \
  -c $MONGODB_COLLECTION \
  --jsonArray \
  --jsonFormat=canonical \
  --quiet | jq > /backup/${MONGODB_COLLECTION}.json
