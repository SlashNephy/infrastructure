# syntax=docker/dockerfile:1
FROM ghcr.io/actions/actions-runner:2.335.1@sha256:08c30b0a7105f64bddfc485d2487a22aa03932a791402393352fdf674bda2c29

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
