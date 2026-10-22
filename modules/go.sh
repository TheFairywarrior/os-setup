#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Go lives in ~/Documents/apps/go (GOROOT), packages in ~/Documents/go (GOPATH).
latest="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"
current="$( [[ -x $GOROOT/bin/go ]] && "$GOROOT/bin/go" env GOVERSION || echo none)"

if [[ $current == "$latest" ]]; then
  ok "Go $current is the latest"
else
  log "installing Go $latest (current: $current)"
  tarball="$latest.linux-$(arch_go).tar.gz"
  curl -fsSL "https://go.dev/dl/$tarball" -o "$WORKDIR/$tarball"
  tar -C "$WORKDIR" -xzf "$WORKDIR/$tarball"
  rm -rf "$GOROOT"
  mkdir -p "$(dirname "$GOROOT")"
  mv "$WORKDIR/go" "$GOROOT"
  ok "Go $latest installed"
fi

# Tools used by helix: language server, linter + its LSP bridge, debugger.
declare -A tools=(
  [gopls]=golang.org/x/tools/gopls@latest
  [golangci-lint]=github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
  [golangci-lint-langserver]=github.com/nametake/golangci-lint-langserver@latest
  [dlv]=github.com/go-delve/delve/cmd/dlv@latest
)
for bin in "${!tools[@]}"; do
  if have "$bin"; then
    ok "$bin already installed"
  else
    log "installing $bin"
    go install "${tools[$bin]}"
  fi
done
