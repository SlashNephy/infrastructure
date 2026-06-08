# syntax=docker/dockerfile:1
FROM ghcr.io/actions/actions-runner:2.335.0@sha256:ccdcb5f6ad3ff02cda20d47544b9bc335b9d555b535fb3556da83e823652a8b4

ARG APT_PACKAGES="build-essential git curl"

USER root

SHELL ["/usr/bin/bash", "-euxo", "pipefail", "-c"]
RUN <<EOF
  apt-get update
  apt-get install -y --no-install-recommends ${APT_PACKAGES}

  apt-get clean
  rm -rf /var/lib/apt/lists/*
EOF

USER runner
