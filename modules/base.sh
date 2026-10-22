#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Build tools and CLI utilities everything else relies on.
if [[ $DISTRO == fedora ]]; then
  pkg_install gcc gcc-c++ make pkgconf-pkg-config openssl-devel libpq-devel \
    curl wget git unzip zip tar jq ripgrep fd-find bat fzf tmux zsh \
    flatpak fontconfig dnf5-plugins
else
  pkg_install build-essential pkg-config libssl-dev libpq-dev ca-certificates gnupg \
    curl wget git unzip zip tar jq ripgrep fd-find bat fzf tmux zsh \
    flatpak fontconfig
  # Ubuntu ships these under different names.
  mkdir -p "$HOME/.local/bin"
  [[ -e $HOME/.local/bin/bat ]] || ln -s /usr/bin/batcat "$HOME/.local/bin/bat"
  [[ -e $HOME/.local/bin/fd ]] || ln -s /usr/bin/fdfind "$HOME/.local/bin/fd"
fi

mkdir -p "$HOME/.local/bin" "$HOME/Documents/apps/bin" "$GOPATH"
ok "base done"
