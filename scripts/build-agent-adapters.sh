#!/usr/bin/env bash
# Build tool-specific agent adapters from initMe/agent/ canonical rules.
# Called by install.sh and bootstrap.sh.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_DIR="$REPO_DIR/agent"
MANIFEST="$AGENT_DIR/manifest.tsv"
CURSOR_RULES_DIR="${CURSOR_RULES_DIR:-$HOME/.cursor/rules}"

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

build_cursor_rules() {
  [[ -f "$MANIFEST" ]] || { echo "missing $MANIFEST" >&2; exit 1; }
  mkdir -p "$CURSOR_RULES_DIR"

  local name source always_apply description
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
  [[ -d "$mylab" ]] || {
    warn "\$HOME/myLab not found; skipping workspace AGENTS.md install"
    return 0
  }
  [[ -f "$template" ]] || { echo "missing $template" >&2; exit 1; }

  link_file "$template" "$mylab/AGENTS.md"
  link_file "$mylab/AGENTS.md" "$mylab/CLAUDE.md"
}

build_cursor_rules
install_claude_adapter
install_mylab_index
