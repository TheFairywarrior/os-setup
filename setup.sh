#!/usr/bin/env bash
# Sets up a Fedora or Ubuntu machine. Safe to re-run.
#   ./setup.sh               run every module
#   ./setup.sh helix go      run only these modules
#   ./setup.sh --list        list modules
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run order matters: base first, helix after the language servers exist.
MODULES=(base git shell fonts python go rust node java helix docker apps flatpak)

usage() {
  sed -n '2,5s/^# \{0,1\}//p' "$0"
  echo
  echo "Modules (in run order): ${MODULES[*]}"
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  -l | --list) printf '%s\n' "${MODULES[@]}"; exit 0 ;;
esac

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root. sudo is used where needed." >&2; exit 1; }

selected=("$@")
((${#selected[@]})) || selected=("${MODULES[@]}")
for m in "${selected[@]}"; do
  [[ -f "$REPO_DIR/modules/$m.sh" ]] || { echo "Unknown module '$m'. Try --list." >&2; exit 1; }
done

LOG_DIR="$HOME/.cache/os-setup"
LOG="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"
[[ -t 1 ]] && export OS_SETUP_COLOR=1
exec > >(tee -a "$LOG") 2>&1

# Ask for the sudo password once and keep it fresh until we exit.
sudo -v
( while kill -0 $$ 2>/dev/null; do sudo -n true; sleep 50; done ) 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill $SUDO_KEEPALIVE 2>/dev/null || true' EXIT

passed=() failed=()
for m in "${selected[@]}"; do
  printf '\n\e[1m━━━ %s ━━━\e[0m\n' "$m"
  # Each module is its own process so `set -e` works and one failure
  # doesn't stop the rest.
  if bash "$REPO_DIR/modules/$m.sh"; then
    passed+=("$m")
  else
    failed+=("$m")
  fi
done

printf '\n\e[1m━━━ summary ━━━\e[0m\n'
for m in "${passed[@]}"; do printf '  \e[32m✔\e[0m %s\n' "$m"; done
for m in "${failed[@]}"; do printf '  \e[31m✘\e[0m %s\n' "$m"; done
echo "Log: $LOG"
((${#failed[@]} == 0)) || { echo "Re-run failed modules with: ./setup.sh ${failed[*]}"; exit 1; }
echo "Done. Open a new terminal (or log out and back in for shell/docker group changes)."
