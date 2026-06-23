# initMe

Personal Mac bootstrap: Homebrew, shell, dotfiles, AI agent rules, infra tools, and `~/myLab` repo sync.

Repos live under **`~/myLab/`** (each project is usually its own git repo). initMe itself is `~/myLab/initMe`.

Targets: **macOS** (`bootstrap.sh`) and **Raspberry Pi OS** (`bootstrap-pi.sh`). There is no single cross-platform bootstrap; each script refuses the wrong OS.

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

### On a machine that already has tools installed

```bash
git clone git@github.com:apoorv-kulkarni/initMe.git ~/myLab/initMe
cd ~/myLab/initMe
./install.sh      # symlinks configs only
exec zsh
```

Run `bash bootstrap.sh` (macOS) or `bash bootstrap-pi.sh` (Pi) if you still need Homebrew packages, launchd sync, etc.

## Review before running

`bootstrap.sh` installs packages, changes macOS system defaults (with a prompt), registers a launchd job, and may generate SSH keys. `--dry-run` previews file/system mutations and skips Homebrew/pyenv environment initialization.

```bash
bash bootstrap.sh --dry-run
```

Or preview the curl installer path:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)" -- --dry-run
```

## Structure

```
initMe/
├── AGENTS.md                 # initMe-specific agent instructions
├── CLAUDE.md                 # @AGENTS.md for Claude Code in this repo
├── install-macos.sh          # curl | bash entry (Homebrew-style)
├── install.sh                # Symlink dotfiles into ~
├── bootstrap.sh              # Full macOS setup (brew bundle, launchd, …)
├── bootstrap-pi.sh           # Raspberry Pi setup
├── clone-mylab.sh            # Clone personal repos into ~/myLab
├── sync-repos.sh             # Fast-forward main/master only under ~/myLab
├── git/
│   └── gitconfig             # Shared git behavior (included from ~/.gitconfig)
├── agent/                      # Canonical agent rules (plain .md)
├── adapters/                   # Claude Code entry point template
├── templates/                  # Workspace AGENTS.md template → ~/myLab/
├── scripts/                    # build-agent-adapters.sh
├── .github/workflows/        # CI (shellcheck on *.sh)
├── .shellcheckrc             # ShellCheck defaults
├── Brewfile                  # Homebrew formulae and casks
├── zshrc                     # Shell config → ~/.zshrc
├── p10k.zsh                  # Powerlevel10k → ~/.p10k.zsh
├── ssh_config                # GitHub SSH → ~/.ssh/config
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
| Dotfiles | `zshrc`, `p10k`, SSH, gitconfig include, global gitignore | `zshrc` + SSH symlinked |
| Agent rules | `agent/` → `~/.cursor/rules/`, `~/.claude/CLAUDE.md`, `~/myLab/AGENTS.md` | — |
| SSH | `id_ed25519` key + keychain; `ssh_config` for GitHub | `id_ed25519` + shared `ssh_config` |
| GitHub CLI | Install + `gh auth login` | Install + `gh auth login` |
| macOS defaults | Finder, key repeat, Dock, screenshots (prompted) | — |
| iTerm2 | Profile imported from repo | — |
| Editors | VS Code + Cursor (casks); VS Code extensions from list | — |
| Repo sync | launchd every 6h: ff-only `main`/`master` under `~/myLab` | cron every 6h |
| CI | ShellCheck on push (`.github/workflows/shellcheck.yml`) | — |

All steps are **idempotent** — safe to re-run if something fails partway through.

`sync-repos.sh` never touches feature branches. Preview:

```bash
bash ~/myLab/initMe/sync-repos.sh --dry-run
```

## Platform handling

- **macOS only**: `bootstrap.sh` and `install-macos.sh` (exit on Linux)
- **Pi / Linux only**: `bootstrap-pi.sh` (apt, cron sync; no Homebrew or macOS defaults)
- **Both**: `install.sh`, `zshrc`, `sync-repos.sh`, `clone-mylab.sh`, `ssh_config`

`zshrc` is shared; platform-specific bits use `uname` checks (e.g. `ls` colors, VS Code PATH). `ssh_config` uses `IgnoreUnknown UseKeychain` so macOS keychain options do not break OpenSSH on Linux/Pi.

## Idempotency

Re-running is intended to be safe: Homebrew bundle upgrades, oh-my-zsh skips if present, SSH keygen only when no key exists, launchd plist skipped if already installed, macOS defaults gated by a marker file (and an interactive prompt on first run). Git **name/email/GPG** are prompted only when `user.name` is unset.

## Keys & secrets

**Not in this repo.** `.gitignore` and `gitignore_global` block keys, `.env`, and common credential files.

On a fresh machine, bootstrap will:

1. Generate or import an SSH key (`~/.ssh/id_ed25519`) and load it into the macOS keychain (Pi: keygen without keychain)
2. Symlink `ssh_config` to `~/.ssh/config` (backs up a plain file to `~/.ssh/config.bak.<timestamp>` first)
3. Run `gh auth login` for GitHub
4. **Prompt** for git name / email / optional GPG key when `user.name` is not set (stored in `~/.gitconfig`, not in this repo)

`ssh_config` points GitHub at `id_ed25519` (bootstrap default), then
`gigithub_2024` and `github_rsa` as fallbacks. OpenSSH skips missing keys.
`IdentitiesOnly yes` limits which keys are offered to GitHub.

Vault is installed via Homebrew on macOS; log in manually when you need it (`vault login`).

## GPG commit signing (optional)

Bootstrap prompts for a signing key ID on first run. To enable later:

```bash
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
git config --global gpg.program gpg   # or /opt/homebrew/bin/gpg on Apple Silicon
```

## AI agent config

**Canonical rules** live in `agent/` (plain Markdown). `install.sh` runs
`scripts/build-agent-adapters.sh` to install tool-specific adapters:

| Tool | Installed path |
| --- | --- |
| Cursor | `~/.cursor/rules/*.mdc` (generated from `agent/manifest.tsv`) |
| Claude Code | `~/.claude/CLAUDE.md` |
| Workspace index | `~/myLab/AGENTS.md` and `~/myLab/CLAUDE.md` (symlink) |

Read `AGENTS.md` at the initMe repo root before editing bootstrap scripts.
Open **`~/myLab`** as the Cursor workspace; optionally copy
`mylab.cursorignore.example` to `~/myLab/.cursorignore`.

See `agent/README.md` for layout and how to add rules.

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

This also regenerates `~/.cursor/rules/` from `agent/` and refreshes Claude
and `~/myLab/AGENTS.md` adapters.

## Dotfiles are symlinked, not copied

`zshrc`, `p10k.zsh`, `ssh_config`, and `gitignore_global` are symlinked from this repo. `bootstrap.sh`, `bootstrap-pi.sh`, and `install.sh` all link `ssh_config` → `~/.ssh/config`; they back up an existing plain file to `~/.ssh/config.bak.<timestamp>` before replacing it with a symlink.

`git/gitconfig` is **included** from `~/.gitconfig` so your identity stays local. Agent rules in `agent/` install to `~/.cursor/rules/` and `~/.claude/CLAUDE.md` via `install.sh`.

## Development

Shell scripts are checked on push with [ShellCheck](https://www.shellcheck.net/) (see `.github/workflows/shellcheck.yml` and `.shellcheckrc`). Local check:

```bash
shellcheck *.sh
```

## Keeping packages up to date

```bash
brew bundle dump --force   # regenerate Brewfile from installed packages
```

## Logs

Repo sync: `~/logs/sync-repos.log`. launchd (macOS) also writes `~/logs/sync-repos-launchd.log`.
