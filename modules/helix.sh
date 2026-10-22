#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if [[ $DISTRO == fedora ]]; then
  pkg_install helix
else
  # Ubuntu's archive and the helix PPA lag far behind, and the config needs
  # >= 25.01 (%{buffer_name}). Use the .deb from the official GitHub release.
  release="$(curl -fsSL https://api.github.com/repos/helix-editor/helix/releases/latest)"
  latest="$(jq -r .tag_name <<<"$release")"
  current="$(have hx && hx --version | awk '{print $2}' || echo none)"
  if [[ $current == "$latest" ]]; then
    ok "helix $current is the latest"
  else
    [[ "$(dpkg --print-architecture)" == amd64 ]] || die "helix only publishes an amd64 .deb"
    log "installing helix $latest (current: $current)"
    install_remote_pkg "$(jq -r '.assets[] | select(.name | endswith("_amd64.deb")) | .browser_download_url' <<<"$release")"
  fi
fi

link "$REPO_DIR/dotfiles/helix" "$HOME/.config/helix"

# Show whether the language servers from the other modules are visible.
for lang in python go rust; do
  hx --health "$lang" || true
done
