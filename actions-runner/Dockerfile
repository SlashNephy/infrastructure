# syntax=docker/dockerfile:1
FROM ghcr.io/actions/actions-runner:2.338.1@sha256:e275409999c37162649aa050ca573f03eab2eabcb3a1e7fcc47548de6b4f9690

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
