# initMe

New machine setup for macOS (and partially Raspberry Pi). Run once when moving to a new laptop.

## What it does

1. Installs Xcode Command Line Tools and Homebrew
2. Installs all packages and apps via `Brewfile` (`brew bundle`)
3. Installs the latest Terraform (via tfenv) and Python (via pyenv)
4. Generates an SSH key and authenticates the GitHub CLI
5. Installs oh-my-zsh + Powerlevel10k and copies `zshrc`
6. Applies sensible macOS system defaults (Finder, key repeat, screenshots, Dock)
7. Sets up a launchd agent to `git fetch` all repos in `~/myLab` every 6 hours
8. Installs VS Code extensions from `vscode-extensions-list.txt`

## Usage

```bash
git clone git@github.com:apoorv-kulkarni/initMe.git
cd initMe
bash bootstrap.sh
```

> **Before running:** fill in and uncomment the git config section at the bottom of `bootstrap.sh` with your name, email, and GPG signing key.

## Files

| File | Purpose |
| --- | --- |
| `bootstrap.sh` | Main setup script — run this |
| `Brewfile` | All Homebrew packages and cask apps |
| `zshrc` | Shell config (oh-my-zsh, p10k, pyenv, Go, aliases, functions) |
| `vscode-extensions-list.txt` | VS Code extensions to install |
| `sync-repos.sh` | Fetches updates for all git repos under `~/myLab` |

## Keeping packages up to date

To update the `Brewfile` to match what's currently installed on your machine:

```bash
brew bundle dump --force
```

## Raspberry Pi

`bootstrap.sh` is macOS-only. On a Pi, manually install packages and add repo sync to cron:

```bash
crontab -e
# add:
0 */6 * * * /bin/bash $HOME/myLab/initMe/sync-repos.sh
```
