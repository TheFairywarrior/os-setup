#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Python is managed entirely by uv: interpreters, tools and project venvs.
if have uv; then
  ok "uv already installed ($(uv --version))"
  uv self update || warn "uv self update failed (fine if uv came from a package manager)"
else
  log "installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi

# Latest CPython, also exposed as python/python3 in ~/.local/bin.
uv python install --default

# Language servers used by helix, plus pre-commit for git hooks.
for tool in ruff pyright pre-commit; do
  uv tool install "$tool"
done
ok "python done"
