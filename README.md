# initMe

The fastest way to go from a blank machine to a fully configured dev environment — optimized for infra/SRE work. Born out of me getting really tired of manually moving configs between Macs.

Targets: **macOS** (primary) and **Raspberry Pi OS** (Debian).

## What it does

| Step | macOS | Pi |
| --- | --- | --- |
| Core packages | `brew bundle` (Brewfile) | `apt` + manual binaries |
| Languages | Go, Python (pyenv), .NET | Go, Python (pyenv) |
| Infrastructure | Terraform (tfenv), Vault | Terraform (tfenv) |
| Kubernetes | kubectl, kubectx, kubelogin, k9s, minikube | kubectl, kubectx, k9s |
| Shell | oh-my-zsh + Powerlevel10k + plugins | oh-my-zsh + Powerlevel10k + plugins |
| Dotfiles | `zshrc` symlinked from repo | `zshrc` symlinked from repo |
| SSH | Generate or import + keychain | Generate or import |
| GitHub CLI | Install + `gh auth login` | Install + `gh auth login` |
| macOS defaults | Finder, key repeat, Dock, screenshots | — |
| iTerm2 | Profile imported from repo | — |
| Repo sync | launchd agent (every 6h) | cron (every 6h) |
| VS Code | Extensions from list | — |

All steps are **idempotent** — safe to re-run if something fails partway through.

## Usage

### macOS

```bash
git clone git@github.com:apoorv-kulkarni/initMe.git ~/myLab/initMe
cd ~/myLab/initMe
bash bootstrap.sh
```

### Raspberry Pi

```bash
git clone git@github.com:apoorv-kulkarni/initMe.git ~/myLab/initMe
cd ~/myLab/initMe
bash bootstrap-pi.sh
```

> Both scripts prompt interactively for git name/email/signing key — no manual editing required before running.

Pass `--dry-run` to preview what each step would do without making any changes:

```bash
bash bootstrap.sh --dry-run
```

## Files

| File | Purpose |
| --- | --- |
| `bootstrap.sh` | macOS setup — run this |
| `bootstrap-pi.sh` | Raspberry Pi setup — run this |
| `Brewfile` | All Homebrew formulae and cask apps |
| `zshrc` | Shell config — symlinked to `~/.zshrc` |
| `p10k.zsh` | Powerlevel10k prompt config — symlinked to `~/.p10k.zsh` |
| `ssh_config` | SSH client config — symlinked to `~/.ssh/config` |
| `gitignore_global` | Global gitignore — wired via `core.excludesfile` |
| `iterm2_profile.plist` | iTerm2 preferences — imported on bootstrap |
| `vscode-extensions-list.txt` | VS Code extensions to install |
| `sync-repos.sh` | Fetches updates for all git repos under `~/myLab` |

## Dotfiles are symlinked, not copied

`zshrc`, `p10k.zsh`, `ssh_config`, and `gitignore_global` are all symlinked from this repo into their expected locations. Edits on the live files are automatically in version control — no drift, no manual syncing.

## Keeping packages up to date

To regenerate `Brewfile` from whatever's currently installed:

```bash
brew bundle dump --force
```

## Logs

Repo sync logs live at `~/logs/sync-repos.log`. The launchd agent (macOS) also writes to `~/logs/sync-repos-launchd.log`.
