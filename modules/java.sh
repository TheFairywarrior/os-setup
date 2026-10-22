#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

export SDKMAN_DIR="$HOME/.sdkman"

if [[ -s $SDKMAN_DIR/bin/sdkman-init.sh ]]; then
  ok "SDKMAN already installed"
else
  log "installing SDKMAN"
  # rcupdate=false: SDKMAN is loaded by dotfiles/zsh/my_profile instead.
  curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash
fi

# SDKMAN isn't compatible with `set -u`.
set +u
# shellcheck source=/dev/null
. "$SDKMAN_DIR/bin/sdkman-init.sh"

for candidate in java kotlin gradle; do
  if [[ -d $SDKMAN_DIR/candidates/$candidate/current ]]; then
    ok "$candidate already installed"
  else
    log "installing $candidate"
    # Feed "y" to the "set as default?" prompt.
    sdk install "$candidate" < <(yes)
  fi
done
set -u
