#!/usr/bin/env bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Entries are "<flatpak id>" or "<flatpak id>:<command>". An app is skipped if
# it's already a flatpak (any scope, any id casing) or the command exists,
# e.g. Slack installed natively.
apps=(
  com.slack.Slack:slack
  com.discordapp.Discord:discord
  us.zoom.Zoom:zoom
  org.mozilla.Thunderbird:thunderbird
  org.videolan.VLC:vlc
  org.onlyoffice.desktopeditors
  com.jgraph.drawio.desktop
)

pkg_install flatpak
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

installed="$(flatpak list --app --columns=application)"
to_install=()
for entry in "${apps[@]}"; do
  id=${entry%%:*} cmd=${entry#*:}
  if grep -qix "$id" <<<"$installed" || { [[ $cmd != "$entry" ]] && have "$cmd"; }; then
    ok "$id already installed"
  else
    to_install+=("$id")
  fi
done

if ((${#to_install[@]})); then
  log "installing: ${to_install[*]}"
  flatpak install --user -y --noninteractive flathub "${to_install[@]}"
fi
ok "flatpak done"
