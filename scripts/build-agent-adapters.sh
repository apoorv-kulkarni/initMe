#!/usr/bin/env bash
# Build tool-specific agent adapters from initMe/agent/ canonical rules.
# Called by install.sh and bootstrap.sh.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_DIR="$REPO_DIR/agent"
MANIFEST="$AGENT_DIR/manifest.tsv"
CURSOR_RULES_DIR="${CURSOR_RULES_DIR:-$HOME/.cursor/rules}"
CURSOR_STAMP="$CURSOR_RULES_DIR/.initme-managed-rules"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[initMe]${NC} $*"; }
warn()  { echo -e "${YELLOW}[initMe]${NC} $*"; }

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

install_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    info "Up to date: $dst"
    return 0
  elif [[ -f "$dst" ]]; then
    warn "Backing up existing $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  cp "$src" "$dst"
  info "Installed $dst"
}

prune_removed_cursor_rules() {
  local -a current=("$@")
  [[ -f "$CURSOR_STAMP" ]] || return 0

  local old_name
  while IFS= read -r old_name; do
    [[ -n "$old_name" ]] || continue
    local found=0 name
    for name in "${current[@]}"; do
      if [[ "$name" == "$old_name" ]]; then
        found=1
        break
      fi
    done
    if [[ "$found" -eq 0 && -f "$CURSOR_RULES_DIR/$old_name" ]]; then
      rm -f "$CURSOR_RULES_DIR/$old_name"
      warn "Removed stale Cursor rule $CURSOR_RULES_DIR/$old_name"
    fi
  done <"$CURSOR_STAMP"
}

build_cursor_rules() {
  [[ -f "$MANIFEST" ]] || { echo "missing $MANIFEST" >&2; exit 1; }
  mkdir -p "$CURSOR_RULES_DIR"

  local -a manifest_names=()
  local name source always_apply description
  while IFS=$'\t' read -r name source always_apply description; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    manifest_names+=("$name")
  done <"$MANIFEST"

  prune_removed_cursor_rules "${manifest_names[@]}"

  while IFS=$'\t' read -r name source always_apply description; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    local src="$AGENT_DIR/$source"
    [[ -f "$src" ]] || { echo "missing source: $src" >&2; exit 1; }

    local out="$CURSOR_RULES_DIR/$name"
    rm -f "$out"
    {
      printf '%s\n' '---'
      printf 'description: %s\n' "$description"
      printf 'alwaysApply: %s\n' "$always_apply"
      printf '%s\n' '---'
      printf '\n'
      cat "$src"
    } >"$out"
    info "Built $out"
  done <"$MANIFEST"

  printf '%s\n' "${manifest_names[@]}" >"$CURSOR_STAMP"
}

install_claude_adapter() {
  local src="$REPO_DIR/adapters/claude-global.md"
  [[ -f "$src" ]] || { echo "missing $src" >&2; exit 1; }
  mkdir -p "$HOME/.claude"
  link_file "$src" "$HOME/.claude/CLAUDE.md"
}

install_mylab_index() {
  local mylab="$HOME/myLab"
  local template="$REPO_DIR/templates/mylab-AGENTS.md"
  local claude_template="$REPO_DIR/adapters/mylab-CLAUDE.md"
  [[ -d "$mylab" ]] || {
    warn "\$HOME/myLab not found; skipping workspace AGENTS.md install"
    return 0
  }
  [[ -f "$template" ]] || { echo "missing $template" >&2; exit 1; }
  [[ -f "$claude_template" ]] || { echo "missing $claude_template" >&2; exit 1; }

  link_file "$template" "$mylab/AGENTS.md"
  install_file "$claude_template" "$mylab/CLAUDE.md"
}

build_cursor_rules
install_claude_adapter
install_mylab_index
