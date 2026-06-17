# initMe

Personal Mac bootstrap: Homebrew, shell, dotfiles, Cursor rules, infra tools, and `~/myLab` repo sync.

Repos live under **`~/myLab/`** (each project is usually its own git repo). initMe itself is `~/myLab/initMe`.

Targets: **macOS** (primary) and **Raspberry Pi OS** (Debian).

## Quick Start

### On a new Mac (full setup from scratch)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)"
```

Then clone the rest of your repos:

```bash
cd ~/myLab/initMe
bash clone-mylab.sh
exec zsh
```

Preview bootstrap without applying changes:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)" -- --dry-run
```

### On a machine that already has tools installed

```bash
git clone git@github.com:apoorv-kulkarni/initMe.git ~/myLab/initMe
cd ~/myLab/initMe
./install.sh      # symlinks configs only
exec zsh
```

Run `bash bootstrap.sh` (macOS) or `bash bootstrap-pi.sh` (Pi) if you still need Homebrew packages, launchd sync, etc.

## Structure

```
initMe/
├── install-macos.sh          # curl | bash entry (Homebrew-style)
├── install.sh                # Symlink dotfiles into ~
├── bootstrap.sh              # Full macOS setup (brew bundle, launchd, …)
├── bootstrap-pi.sh           # Raspberry Pi setup
├── clone-mylab.sh            # Clone personal repos into ~/myLab
├── sync-repos.sh             # Fast-forward main/master only under ~/myLab
├── git/
│   └── gitconfig             # Shared git behavior (included from ~/.gitconfig)
├── cursor-rules/             # Global Cursor rules → ~/.cursor/rules/
├── Brewfile                  # Homebrew formulae and casks
├── zshrc                     # Shell config → ~/.zshrc
├── p10k.zsh                  # Powerlevel10k → ~/.p10k.zsh
├── ssh_config                # SSH client config → ~/.ssh/config
├── gitignore_global          # Global gitignore → core.excludesfile
├── mylab.cursorignore.example
└── vscode-extensions-list.txt
```

## What it does

| Step | macOS | Pi |
| --- | --- | --- |
| Core packages | `brew bundle` (Brewfile) | `apt` + manual binaries |
| Languages | Go, Python (pyenv) | Go, Python (pyenv) |
| Infrastructure | Terraform (tfenv), Vault | Terraform (tfenv) |
| Kubernetes | kubectl, kubectx, kubelogin, k9s, minikube | kubectl, kubectx, k9s |
| Shell | oh-my-zsh + Powerlevel10k + plugins | oh-my-zsh + Powerlevel10k + plugins |
| Dotfiles | `zshrc`, `p10k`, SSH, gitconfig include, global gitignore | `zshrc` symlinked |
| Cursor rules | `cursor-rules/*.mdc` → `~/.cursor/rules/` | — |
| SSH | Generate or import + keychain | Generate or import |
| GitHub CLI | Install + `gh auth login` | Install + `gh auth login` |
| macOS defaults | Finder, key repeat, Dock, screenshots | — |
| iTerm2 | Profile imported from repo | — |
| Editors | VS Code + Cursor (casks); VS Code extensions from list | — |
| Repo sync | launchd every 6h: ff-only `main`/`master` under `~/myLab` | cron every 6h |

All steps are **idempotent** — safe to re-run if something fails partway through.

`sync-repos.sh` never touches feature branches. Preview:

```bash
bash ~/myLab/initMe/sync-repos.sh --dry-run
```

## Platform handling

- **macOS**: Homebrew (`Brewfile`), iTerm2 profile, macOS defaults, VS Code extensions
- **Raspberry Pi / Linux**: `bootstrap-pi.sh`, apt-based tools, cron instead of launchd

`zshrc` is shared; platform-specific bits use `uname` checks (e.g. `ls` colors, VS Code PATH).

## Keys & secrets

**Not in this repo.** `.gitignore` and `gitignore_global` block keys, `.env`, and common credential files.

On a fresh machine, bootstrap will:

1. Generate or import an SSH key and load it into the macOS keychain
2. Run `gh auth login` for GitHub
3. Prompt for git name / email (stored in `~/.gitconfig`, not in the repo)

Vault is installed via Homebrew for personal infra work; log in manually when you need it (`vault login`).

## GPG commit signing (optional)

Bootstrap prompts for a signing key ID on first run. To enable later:

```bash
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
git config --global gpg.program gpg   # or /opt/homebrew/bin/gpg on Apple Silicon
```

## Cursor AI config

`cursor-rules/*.mdc` are symlinked to `~/.cursor/rules/` and cover interaction style, coding standards, `~/myLab` layout, debugging habits, and PR cleanup. Open **`~/myLab`** as the workspace; optionally copy `mylab.cursorignore.example` to `~/myLab/.cursorignore`.

## Other install paths

### curl installer — custom parent directory

Creates `<dir>/initMe`:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)" -- "$HOME/code"
```

### Tarball install → normal git clone

After `gh auth login`:

```bash
cd ~/myLab/initMe
git init
git remote add origin git@github.com:apoorv-kulkarni/initMe.git
git fetch origin
git reset --hard FETCH_HEAD
git branch -M master
```

### Raspberry Pi

```bash
git clone git@github.com:apoorv-kulkarni/initMe.git ~/myLab/initMe
cd ~/myLab/initMe
bash bootstrap-pi.sh
```

### Refresh symlinks after `git pull`

```bash
cd ~/myLab/initMe && bash install.sh
```

## Dotfiles are symlinked, not copied

`zshrc`, `p10k.zsh`, `ssh_config`, and `gitignore_global` are symlinked. `git/gitconfig` is **included** from `~/.gitconfig` so your identity stays local. `cursor-rules/*.mdc` symlink to `~/.cursor/rules/`.

## Keeping packages up to date

```bash
brew bundle dump --force   # regenerate Brewfile from installed packages
```

## Logs

Repo sync: `~/logs/sync-repos.log`. launchd (macOS) also writes `~/logs/sync-repos-launchd.log`.
