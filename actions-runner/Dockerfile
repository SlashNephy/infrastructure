# syntax=docker/dockerfile:1
FROM ghcr.io/actions/actions-runner:2.333.0@sha256:1ad983536759ceec39ed75a2c8f007ca8c37b66eee35ed86f13623b29a4db97d

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
