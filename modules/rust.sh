#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

components=(rust-analyzer clippy rustfmt)

if have rustup; then
  ok "rustup already installed"
  rustup update stable
else
  log "installing rustup"
  # PATH is handled by dotfiles/zsh/my_profile, so don't let rustup edit rc files.
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --no-modify-path --default-toolchain stable
fi

rustup component add "${components[@]}"

# Debug adapter helix uses for rust (lldb-dap).
pkg_install lldb
if ! have lldb-dap; then
  # Ubuntu only ships versioned binaries, e.g. /usr/bin/lldb-dap-18.
  dap="$(compgen -G '/usr/bin/lldb-dap-*' | sort -V | tail -n1 || true)"
  [[ -n $dap ]] || die "lldb installed but no lldb-dap binary found"
  ln -s "$dap" "$HOME/.local/bin/lldb-dap"
  ok "linked lldb-dap -> $dap"
fi
ok "rust done ($(rustc --version))"
