# os-setup

Sets up a Fedora or Ubuntu (or Ubuntu-based) machine with my apps, dev environments and dotfiles. It's safe to re-run: each step checks whether its work is already done and skips it if so.

```sh
git clone <this repo> ~/Documents/os-setup
cd ~/Documents/os-setup
./setup.sh              # everything
./setup.sh helix go     # just these modules
./setup.sh --list
```

You're asked for your sudo password once, at the start. Each module runs separately, so a failure in one doesn't stop the rest. At the end you get a summary of what passed and failed and the log path (`~/.cache/os-setup/`). It also prints the command to re-run only the failed modules.

## Modules

| Module | What it does |
|---|---|
| `base` | Compilers, build headers, curl/git/jq/ripgrep/fd/bat/fzf/tmux/zsh/flatpak, and the `~/Documents/apps/bin` folder |
| `git` | Sets git name, email, default branch and editor. Values that are already set are left alone |
| `shell` | oh-my-zsh, starship, symlinks `~/.zshrc` and `~/.my_profile`, makes zsh the login shell |
| `fonts` | 0xProto Nerd Font |
| `python` | uv, the latest CPython (`uv python install --default`), ruff, pyright and pre-commit |
| `go` | Latest Go in `~/Documents/apps/go`, plus gopls, golangci-lint (+ langserver) and dlv |
| `rust` | rustup (stable) with rust-analyzer, clippy and rustfmt, plus lldb (`lldb-dap`) for debugging |
| `node` | nvm and the Node LTS release |
| `java` | SDKMAN with java, kotlin and gradle |
| `helix` | helix, symlinks `~/.config/helix`, prints `hx --health` for python/go/rust |
| `docker` | Docker Engine + compose (skipped if `docker` already exists), adds you to the `docker` group |
| `apps` | DBeaver, VS Code, kitty (+ symlinks `~/.config/kitty`), lazygit, gh, glab, gitleaks, 1Password, Chrome |
| `flatpak` | Slack, Discord, Zoom, Thunderbird, VLC, ONLYOFFICE, draw.io |

## Dotfiles

`dotfiles/` is symlinked into `$HOME`, so editing `~/.config/helix/config.toml` edits the file in this repo. Commit the change to sync it to other machines. When a symlink replaces an existing file, the file is first moved to `<name>.bak-<timestamp>`.

Machine-specific shell config (work tools, gcloud and so on) goes in `~/.zshrc.local`. That file isn't tracked.

## Layout

```
setup.sh          entrypoint: module order, logging, summary
lib/common.sh     helpers: pkg_install, add_repo_fedora/add_repo_apt, install_remote_pkg, link, ...
modules/*.sh      one file per area; each can also be run on its own: bash modules/go.sh
dotfiles/         helix + kitty + zsh config
```

## Adding things

- **A distro package**: add it to `pkg_install` in `modules/apps.sh`. If the names differ between distros, add it inside the `$DISTRO` branch.
- **A package from a vendor repo**: add the repo with `add_repo_fedora` / `add_repo_apt`, then call `pkg_install`.
- **A flatpak**: add its id to `apps` in `modules/flatpak.sh`. Append `:command` to skip it when a native install exists.
- **A new module**: create `modules/<name>.sh` starting with the same `source .../lib/common.sh` line, then add `<name>` to `MODULES` in `setup.sh`.

## Git hooks

`.pre-commit-config.yaml` runs gitleaks, shellcheck and some whitespace/YAML/TOML checks on each commit. Enable it once per clone with `pre-commit install` (pre-commit comes from the `python` module).
