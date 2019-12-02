#!/usr/bin/env bash
REPO_PATH="$(git rev-parse --show-toplevel)"
CONFIG_ARGS=""

if [ ! -z "$GITLEAKS_CONFIG" ]; then
  CONFIG_ARGS="--config=${GITLEAKS_CONFIG}"
elif [ -f "${REPO_PATH}/.gitleaks.toml" ]; then
  CONFIG_ARGS="--repo-config"
fi

gitleaks $CONFIG_ARGS --verbose --pretty