#!/usr/bin/env bash
set -euo pipefail

# Fast-forward the default branch (main/master) of every git repo under
# ~/myLab to match origin. Feature branches are NEVER touched.
#
# macOS: managed by launchd — see bootstrap.sh (every 6 hours)
# Raspberry Pi / Linux: add to crontab with:
#   crontab -e
#   0 */6 * * * /bin/bash $HOME/myLab/initMe/sync-repos.sh
#
# Behavior per repo:
#   - fetch origin's default branch
#   - if local default is strictly behind origin AND a clean fast-forward:
#       * checked out  -> real `git merge --ff-only` (updates index+worktree),
#                         skipped if the tree is dirty
#       * not checked out -> bare `git update-ref` (moves the ref only)
#   - diverged default, dirty checked-out tree, or any non-default branch:
#     left untouched.
#
# Usage: sync-repos.sh [--dry-run] [repos_dir]
#   repos_dir defaults to $HOME/myLab

DRY_RUN=false
REPOS_DIR="${HOME}/myLab"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  shift
fi

if [[ -n "${1:-}" ]]; then
  REPOS_DIR="$1"
fi

LOG_DIR="${HOME}/logs"
LOG_FILE="${LOG_DIR}/sync-repos.log"
mkdir -p "$LOG_DIR"

# Repos to skip (bare names, not full paths)
EXCLUDE_REPOS=(
  # "big-monorepo"
)

# Paths to skip entirely (full paths or prefix globs)
EXCLUDE_PATHS=(
  # "${HOME}/myLab/archived"
)

is_excluded() {
  local repo_path="$1"
  local repo_name
  repo_name="$(basename "$repo_path")"

  for name in ${EXCLUDE_REPOS[@]+"${EXCLUDE_REPOS[@]}"}; do
    [[ "$repo_name" == "$name" ]] && return 0
  done

  for path in ${EXCLUDE_PATHS[@]+"${EXCLUDE_PATHS[@]}"}; do
    [[ "$repo_path" == "$path"* ]] && return 0
  done

  return 1
}

log() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }

# Resolve the remote default branch: prefer origin/HEAD after fetch, else main/master.
resolve_default_branch() {
  local branch=""
  branch="$(git symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)"
  if [[ -z "$branch" ]]; then
    for candidate in main master; do
      if git rev-parse --verify "refs/remotes/origin/${candidate}" &>/dev/null; then
        branch="$candidate"
        break
      fi
    done
  fi
  printf '%s' "$branch"
}

sync_repo() {
  local repo_path="$1"
  local repo_name
  repo_name="$(basename "$repo_path")"

  cd "$repo_path" 2>/dev/null || return 0
  [[ -d .git ]] || return 0

  if is_excluded "$repo_path"; then
    log "[$repo_name] SKIP - excluded"
    return 0
  fi

  if ! git fetch origin --prune --quiet 2>/dev/null; then
    log "[$repo_name] SKIP - fetch failed (network/auth)"
    return 0
  fi

  local default_branch
  default_branch="$(resolve_default_branch)"
  if [[ -z "$default_branch" ]]; then
    log "[$repo_name] SKIP - no default branch found (origin/HEAD, main, or master)"
    return 0
  fi

  # Nothing to do if the local default branch doesn't exist yet
  git rev-parse --verify "refs/heads/${default_branch}" &>/dev/null || return 0

  # Only ever fast-forward: bail if local default has diverged from origin
  if ! git merge-base --is-ancestor "refs/heads/${default_branch}" "origin/${default_branch}" 2>/dev/null; then
    log "[$repo_name] SKIP $default_branch - diverged from origin (not a fast-forward)"
    return 0
  fi

  local local_sha remote_sha
  local_sha=$(git rev-parse "refs/heads/${default_branch}")
  remote_sha=$(git rev-parse "origin/${default_branch}")
  [[ "$local_sha" == "$remote_sha" ]] && return 0

  local cur
  cur=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")

  if $DRY_RUN; then
    log "[$repo_name] WOULD fast-forward $default_branch (${local_sha:0:8}..${remote_sha:0:8})"
    return 0
  fi

  if [[ "$cur" == "$default_branch" ]]; then
    # Default branch is checked out: update index + worktree via a real
    # ff-only, and only when the tree is clean so we never clobber work.
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
      log "[$repo_name] SKIP ff $default_branch - checked out and dirty"
    elif git merge --ff-only "origin/${default_branch}" --quiet 2>/dev/null; then
      log "[$repo_name] fast-forwarded $default_branch (checked-out)"
    else
      log "[$repo_name] SKIP ff $default_branch - checked out, ff-only failed"
    fi
  else
    # Default branch not checked out: move the ref directly (no worktree
    # is touched, so this is safe and is the whole point).
    if git update-ref "refs/heads/${default_branch}" "origin/${default_branch}" 2>/dev/null; then
      log "[$repo_name] fast-forwarded $default_branch"
    else
      log "[$repo_name] SKIP $default_branch - update-ref failed"
    fi
  fi
}

log "=== default-branch sync start $(if $DRY_RUN; then echo "(DRY RUN)"; fi) under $REPOS_DIR ==="

while IFS= read -r git_dir; do
  sync_repo "$(dirname "$git_dir")"
done < <(find "$REPOS_DIR" -maxdepth 2 -name ".git" -type d 2>/dev/null | sort)

log "=== default-branch sync complete ==="

# Keep log from growing unbounded
if [[ -f "$LOG_FILE" ]]; then
  tail -2000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi
