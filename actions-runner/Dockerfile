# syntax=docker/dockerfile:1
FROM ghcr.io/actions/actions-runner:2.333.1@sha256:b57864c9fcda15ea4a270446aa9cfb108b819a26f6e71fc515f6caf6c27989c6

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
