#!/usr/bin/env bash
# Symlink initMe dotfiles, Cursor rules, and helper scripts into $HOME.
# Lightweight alternative to bootstrap.sh when the machine is already set up.
#
# Usage: bash install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[initMe]${NC} $*"; }
warn()  { echo -e "${YELLOW}[initMe]${NC} $*"; }
error() { echo -e "${RED}[initMe]${NC} $*" >&2; }

link_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -f "$dst" ]]; then
    warn "Backing up existing $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sf "$src" "$dst"
  info "Linked $dst -> $src"
}

info "Platform: $(uname -s)/$(uname -m)"

# --- Shell ---
link_file "$REPO_DIR/zshrc" "$HOME/.zshrc"
link_file "$REPO_DIR/p10k.zsh" "$HOME/.p10k.zsh"

# --- Git ---
link_file "$REPO_DIR/gitignore_global" "$HOME/.gitignore_global"
git config --global core.excludesfile "$HOME/.gitignore_global"
GITCONFIG_INCLUDE="$REPO_DIR/git/gitconfig"
if [[ -f "$GITCONFIG_INCLUDE ]]; then
  if ! git config --global --get-all include.path 2>/dev/null | grep -qF "$GITCONFIG_INCLUDE"; then
    git config --global --add include.path "$GITCONFIG_INCLUDE"
  fi
  info "Included $GITCONFIG_INCLUDE in ~/.gitconfig"
fi

# --- SSH ---
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
link_file "$REPO_DIR/ssh_config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# --- Cursor rules ---
mkdir -p "$HOME/.cursor/rules"
for rule in "$REPO_DIR/cursor-rules"/*.mdc; do
  [[ -f "$rule" ]] || continue
  link_file "$rule" "$HOME/.cursor/rules/$(basename "$rule")"
done

# --- Personal scripts (clone-mylab, sync-repos, etc.) ---
mkdir -p "$HOME/.local/bin"
for script in "$REPO_DIR"/*.sh; do
  [[ -f "$script" ]] || continue
  name="$(basename "$script")"
  # bootstrap scripts stay repo-local; install helpers into PATH
  case "$name" in
    bootstrap.sh|bootstrap-pi.sh|install.sh|install-macos.sh) continue ;;
  esac
  link_file "$script" "$HOME/.local/bin/$name"
  chmod +x "$HOME/.local/bin/$name"
done

info "Done. Run 'exec \$SHELL -l' to reload the shell."
