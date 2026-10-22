#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

FONT=0xProto
dest="$HOME/.local/share/fonts/$FONT"

if [[ -d $dest ]]; then
  ok "$FONT Nerd Font already installed"
  exit 0
fi

log "installing $FONT Nerd Font"
curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT.tar.xz" -o "$WORKDIR/font.tar.xz"
mkdir -p "$dest"
tar -xJf "$WORKDIR/font.tar.xz" -C "$dest"
fc-cache -f "$dest"
ok "$FONT Nerd Font installed"
