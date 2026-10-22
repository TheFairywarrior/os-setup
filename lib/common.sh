# Shared helpers. Every module sources this first.
# shellcheck shell=bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_DIR

# Tool locations, so modules can use tools installed by earlier modules
# without needing a new shell. Keep in sync with dotfiles/zsh/my_profile.
export GOROOT="$HOME/Documents/apps/go"
export GOPATH="$HOME/Documents/go"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$GOROOT/bin:$GOPATH/bin:$HOME/Documents/apps/bin:$PATH"
export DEBIAN_FRONTEND=noninteractive

# Per-module scratch dir for downloads, removed on exit.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# ---------------------------------------------------------------- output

if [[ -t 1 || -n "${OS_SETUP_COLOR:-}" ]]; then
  _c_blue=$'\e[34m' _c_green=$'\e[32m' _c_yellow=$'\e[33m' _c_red=$'\e[31m' _c_reset=$'\e[0m'
else
  _c_blue='' _c_green='' _c_yellow='' _c_red='' _c_reset=''
fi

log()  { printf '%s==>%s %s\n' "$_c_blue" "$_c_reset" "$*"; }
ok()   { printf '%s ✔ %s %s\n' "$_c_green" "$_c_reset" "$*"; }
warn() { printf '%s ! %s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
die()  { printf '%s ✘ %s %s\n' "$_c_red" "$_c_reset" "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- distro

# Sets DISTRO=fedora|ubuntu. Ubuntu derivatives (Mint, Pop!_OS) count as ubuntu.
# Also sets CODENAME on ubuntu, for vendor apt repos.
detect_distro() {
  # shellcheck disable=SC1091
  . /etc/os-release
  case " ${ID:-} ${ID_LIKE:-} " in
    *" fedora "*) DISTRO=fedora ;;
    *" ubuntu "*) DISTRO=ubuntu; CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}" ;;
    *) die "Unsupported distro '${ID:-unknown}'. Only Fedora and Ubuntu are supported." ;;
  esac
  export DISTRO CODENAME
}
detect_distro

arch_go() {
  case "$(uname -m)" in
    x86_64) echo amd64 ;;
    aarch64) echo arm64 ;;
    *) die "Unsupported architecture $(uname -m)" ;;
  esac
}

# ---------------------------------------------------------------- packages

pkg_installed() {
  if [[ $DISTRO == fedora ]]; then
    # --whatprovides so e.g. `wget` matches the wget2-wget package.
    rpm -q --whatprovides "$1" >/dev/null 2>&1
  else
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
  fi
}

# Installs only the packages that are missing, so re-runs are quiet and fast.
pkg_install() {
  local missing=() p
  for p in "$@"; do
    pkg_installed "$p" || missing+=("$p")
  done
  if ((${#missing[@]} == 0)); then
    ok "packages already installed: $*"
    return
  fi
  log "installing: ${missing[*]}"
  if [[ $DISTRO == fedora ]]; then
    sudo dnf install -y "${missing[@]}"
  else
    sudo apt-get update -qq
    sudo -E apt-get install -y "${missing[@]}"
  fi
}

# Downloads an .rpm/.deb and installs it with the package manager.
install_remote_pkg() {
  local url=$1 ext
  [[ $DISTRO == fedora ]] && ext=rpm || ext=deb
  local file="$WORKDIR/pkg.$ext"
  log "downloading $url"
  curl -fsSL "$url" -o "$file"
  if [[ $DISTRO == fedora ]]; then
    sudo dnf install -y "$file"
  else
    sudo -E apt-get install -y "$file"
  fi
}

# add_repo_fedora <name> <url-of-.repo-file | literal .repo contents>
add_repo_fedora() {
  local name=$1 src=$2 dest="/etc/yum.repos.d/$1.repo"
  [[ -f $dest ]] && return
  log "adding dnf repo $name"
  if [[ $src == http* ]]; then
    sudo curl -fsSL "$src" -o "$dest"
  else
    printf '%s\n' "$src" | sudo tee "$dest" >/dev/null
  fi
}

copr_enable() {
  local repo=$1
  compgen -G "/etc/yum.repos.d/_copr*:${repo/\//:}.repo" >/dev/null && return
  log "enabling copr $repo"
  sudo dnf copr enable -y "$repo"
}

# add_repo_apt <name> <key-url> <rest of deb line after the [options]>
# e.g. add_repo_apt docker https://.../gpg "https://download.docker.com/linux/ubuntu $CODENAME stable"
add_repo_apt() {
  local name=$1 key_url=$2 rest=$3
  local key="/etc/apt/keyrings/$name.gpg" list="/etc/apt/sources.list.d/$name.list"
  [[ -f $list ]] && return
  log "adding apt repo $name"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "$key_url" -o "$WORKDIR/key"
  if grep -q 'BEGIN PGP' "$WORKDIR/key"; then
    gpg --dearmor <"$WORKDIR/key" | sudo tee "$key" >/dev/null
  else
    sudo cp "$WORKDIR/key" "$key"
  fi
  sudo chmod a+r "$key"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$key] $rest" | sudo tee "$list" >/dev/null
  sudo apt-get update -qq
}

# Latest release tag (e.g. v1.2.3) of a GitHub repo.
github_latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name
}

# ---------------------------------------------------------------- dotfiles

# link <src> <dest>: symlinks dest -> src. A real file or dir already at dest
# is moved aside to dest.bak-<timestamp> first.
link() {
  local src=$1 dest=$2
  if [[ -L $dest && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    ok "$dest already linked"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -e $dest || -L $dest ]]; then
    local backup
    backup="$dest.bak-$(date +%Y%m%d-%H%M%S)"
    warn "moving existing $dest to $backup"
    mv "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  ok "linked $dest -> $src"
}
