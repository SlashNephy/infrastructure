# syntax=docker/dockerfile:1
FROM ghcr.io/actions/actions-runner:2.332.0@sha256:8c3f5970b8ceb90cbd3e89b80c6806bb74d9c31686e9177c743323a4539d12f5

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
