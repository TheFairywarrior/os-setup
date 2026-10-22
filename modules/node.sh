#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

NVM_VERSION=v0.40.3
export NVM_DIR="$HOME/.nvm"

if [[ -s $NVM_DIR/nvm.sh ]]; then
  ok "nvm already installed"
else
  log "installing nvm $NVM_VERSION"
  # PROFILE=/dev/null: nvm is loaded by dotfiles/zsh/my_profile instead.
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
fi

# nvm isn't compatible with `set -u`.
set +u
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh" || true # returns non-zero when no default alias exists yet
nvm install --lts
nvm alias default 'lts/*'
set -u
ok "node $(node --version)"
