#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Docker Engine from Docker's own repos. An existing Docker Desktop install
# also provides `docker`, so it's left alone.
if have docker; then
  ok "docker already installed ($(docker --version))"
else
  if [[ $DISTRO == fedora ]]; then
    add_repo_fedora docker-ce https://download.docker.com/linux/fedora/docker-ce.repo
  else
    add_repo_apt docker https://download.docker.com/linux/ubuntu/gpg \
      "https://download.docker.com/linux/ubuntu $CODENAME stable"
  fi
  pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
fi

if getent group docker >/dev/null && ! id -nG "$USER" | grep -qw docker; then
  log "adding $USER to the docker group (takes effect after logging out)"
  sudo usermod -aG docker "$USER"
fi
ok "docker done"
