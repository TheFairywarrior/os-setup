#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Native (rpm/deb) apps. Sandboxed desktop apps are in flatpak.sh.

pkg_install kitty

# DBeaver: vendor package, no repo.
if pkg_installed dbeaver-ce; then
  ok "dbeaver already installed"
elif [[ $DISTRO == fedora ]]; then
  install_remote_pkg https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm
else
  install_remote_pkg https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
fi

# Google Chrome: the package sets up its own repo for updates.
if pkg_installed google-chrome-stable; then
  ok "chrome already installed"
elif [[ $DISTRO == fedora ]]; then
  install_remote_pkg https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
else
  install_remote_pkg https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
fi

if [[ $DISTRO == fedora ]]; then
  add_repo_fedora vscode '[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc'

  # shellcheck disable=SC2016 # $basearch is expanded by dnf
  add_repo_fedora 1password '[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc'

  copr_enable dejan/lazygit
  pkg_install code 1password gh lazygit
else
  # VS Code's .deb adds its own apt repo; pre-answer the prompt.
  if pkg_installed code; then
    ok "vscode already installed"
  else
    echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
    install_remote_pkg "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  fi

  add_repo_apt 1password https://downloads.1password.com/linux/keys/1password.asc \
    "https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main"
  add_repo_apt github-cli https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    "https://cli.github.com/packages stable main"
  pkg_install 1password gh

  # No maintained apt repo for lazygit: use the release binary.
  if have lazygit; then
    ok "lazygit already installed"
  else
    tag="$(github_latest_tag jesseduffield/lazygit)"
    log "installing lazygit $tag"
    case "$(uname -m)" in x86_64) arch=x86_64 ;; aarch64) arch=arm64 ;; esac
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/$tag/lazygit_${tag#v}_Linux_$arch.tar.gz" |
      tar -xz -C "$HOME/Documents/apps/bin" lazygit
  fi
fi
ok "apps done"
