#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

pkg_install zsh

if [[ -d $HOME/.oh-my-zsh ]]; then
  ok "oh-my-zsh already installed"
else
  log "installing oh-my-zsh"
  # Unattended: don't launch zsh, don't chsh, don't touch .zshrc.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if have starship; then
  ok "starship already installed"
else
  log "installing starship"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

link "$REPO_DIR/dotfiles/zsh/zshrc" "$HOME/.zshrc"
link "$REPO_DIR/dotfiles/zsh/my_profile" "$HOME/.my_profile"

zsh_path="$(command -v zsh)"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$zsh_path" ]]; then
  ok "login shell is already zsh"
else
  log "changing login shell to zsh"
  sudo usermod -s "$zsh_path" "$USER"
fi
