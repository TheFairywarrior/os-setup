#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Only fills in values that are unset, so a machine-specific identity is kept.
set_if_unset() {
  if [[ -z "$(git config --global --get "$1" || true)" ]]; then
    git config --global "$1" "$2"
    ok "git $1 = $2"
  else
    ok "git $1 already set ($(git config --global --get "$1"))"
  fi
}

set_if_unset user.name "Gareth Becker"
set_if_unset user.email "beckergareth38@gmail.com"
set_if_unset init.defaultBranch main
set_if_unset core.editor hx
set_if_unset pull.rebase false
