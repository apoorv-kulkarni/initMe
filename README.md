# initMe

Personal Mac bootstrap: Homebrew, shell, dotfiles, Cursor rules, infra tools, and `~/myLab` repo sync.

Repos live under **`~/myLab/`** (each project is usually its own git repo). initMe itself is `~/myLab/initMe`.

Targets: **macOS** (primary) and **Raspberry Pi OS** (Debian).

## Install (macOS)

Paste in Terminal on a new Mac ([same pattern as Homebrew](https://brew.sh)):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)"
```

Preview what bootstrap would do:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)" -- --dry-run
```

Install under a custom parent directory (creates `<dir>/initMe`):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)" -- "$HOME/code"
```

No `git` required for the first run; `curl` ships with macOS. The installer downloads initMe, then runs `bootstrap.sh` (Homebrew, git, dotfiles, and the rest).

After `gh auth login`, turn the tarball install into a normal clone:

```bash
cd ~/myLab/initMe
git init
git remote add origin git@github.com:apoorv-kulkarni/initMe.git
git fetch origin
git reset --hard FETCH_HEAD
git branch -M master
```

### After bootstrap (recommended)

```bash
cd ~/myLab/initMe
bash clone-mylab.sh    # clone your other GitHub repos into ~/myLab
bash install.sh        # refresh symlinks if you pulled changes (safe to re-run)
```

Open **`~/myLab`** in Cursor. Optional: copy `mylab.cursorignore.example` to `~/myLab/.cursorignore` so sibling repos' `node_modules` and build dirs stay out of AI context.

## What it does

| Step | macOS | Pi |
| --- | --- | --- |
| Core packages | `brew bundle` (Brewfile) | `apt` + manual binaries |
| Languages | Go, Python (pyenv) | Go, Python (pyenv) |
| Infrastructure | Terraform (tfenv), Vault | Terraform (tfenv) |
| Kubernetes | kubectl, kubectx, kubelogin, k9s, minikube | kubectl, kubectx, k9s |
| Shell | oh-my-zsh + Powerlevel10k + plugins | oh-my-zsh + Powerlevel10k + plugins |
| Dotfiles | `zshrc`, `p10k`, SSH, global gitignore symlinked | `zshrc` symlinked |
| Cursor rules | `cursor-rules/*.mdc` symlinked to `~/.cursor/rules/` | — |
| SSH | Generate or import + keychain | Generate or import |
| GitHub CLI | Install + `gh auth login` | Install + `gh auth login` |
| macOS defaults | Finder, key repeat, Dock, screenshots | — |
| iTerm2 | Profile imported from repo | — |
| Editors | VS Code + Cursor (casks); VS Code extensions from list | — |
| Repo sync | launchd every 6h: ff-only `main`/`master` under `~/myLab` | cron every 6h |

All steps are **idempotent** — safe to re-run if something fails partway through.

`sync-repos.sh` never touches feature branches. It only fast-forwards the default branch when origin is ahead and a clean ff-merge is possible (or updates the ref when that branch is not checked out).

Preview sync:

```bash
bash ~/myLab/initMe/sync-repos.sh --dry-run
```

## Other ways to install

### git clone (when git / SSH already work)

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

> Bootstrap scripts prompt for git name/email/signing key — no manual editing required.

### Clone all `~/myLab` repos, then bootstrap

```bash
git clone git@github.com:apoorv-kulkarni/initMe.git ~/myLab/initMe
cd ~/myLab/initMe
bash clone-mylab.sh
bash bootstrap.sh
```

### Already set up — refresh symlinks after `git pull`

`install.sh` re-links dotfiles, Cursor rules, and helper scripts (`clone-mylab`, `sync-repos`) into `~/.local/bin`:

```bash
cd ~/myLab/initMe && bash install.sh
```

Preview bootstrap without changes:

```bash
bash bootstrap.sh --dry-run
```

## Files

| File / directory | Purpose |
| --- | --- |
| `install-macos.sh` | Remote installer: Homebrew-style `curl \| bash` entry |
| `bootstrap.sh` | macOS full setup |
| `bootstrap-pi.sh` | Raspberry Pi setup |
| `install.sh` | Symlink dotfiles, Cursor rules, and helper scripts |
| `clone-mylab.sh` | Clone personal GitHub repos into `~/myLab` |
| `sync-repos.sh` | Fast-forward default branches for repos under `~/myLab` |
| `cursor-rules/` | Global Cursor AI rules (symlinked to `~/.cursor/rules/`) |
| `mylab.cursorignore.example` | Template for `~/myLab/.cursorignore` |
| `.cursorignore` | Keeps large initMe blobs out of Cursor context |
| `Brewfile` | Homebrew formulae and cask apps |
| `zshrc` | Shell config — symlinked to `~/.zshrc` |
| `p10k.zsh` | Powerlevel10k prompt — symlinked to `~/.p10k.zsh` |
| `ssh_config` | SSH client config — symlinked to `~/.ssh/config` |
| `gitignore_global` | Global gitignore — `core.excludesfile` |
| `iterm2_profile.plist` | iTerm2 preferences — imported on bootstrap |
| `vscode-extensions-list.txt` | VS Code extensions (`code --install-extension`) |

## Dotfiles are symlinked, not copied

`zshrc`, `p10k.zsh`, `ssh_config`, `gitignore_global`, and `cursor-rules/*.mdc` are symlinked from this repo. Edits on the live files stay in version control — no drift, no manual syncing.

## Keeping packages up to date

Regenerate `Brewfile` from whatever is currently installed:

```bash
brew bundle dump --force
```

## Logs

Repo sync: `~/logs/sync-repos.log`. launchd (macOS) also writes `~/logs/sync-repos-launchd.log`.
