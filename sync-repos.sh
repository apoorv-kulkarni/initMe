#!/bin/bash
# sync-repos.sh — fetch updates for all git repos under REPOS_DIR
#
# macOS: managed by launchd — see bootstrap.sh for setup
# Raspberry Pi / Linux: add to crontab with:
#   crontab -e
#   0 */6 * * * /bin/bash $HOME/myLab/initMe/sync-repos.sh

REPOS_DIR="${1:-$HOME/myLab}"
LOG_DIR="$HOME/logs"
LOG_FILE="$LOG_DIR/sync-repos.log"
MAX_LOG_LINES=1000

mkdir -p "$LOG_DIR"

# Rotate log if it gets too long
if [[ -f "$LOG_FILE" ]] && [[ $(wc -l < "$LOG_FILE") -gt $MAX_LOG_LINES ]]; then
    tail -n $MAX_LOG_LINES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"

# Find all git repos up to 2 levels deep
find "$REPOS_DIR" -maxdepth 2 -name ".git" -type d | sort | while read -r git_dir; do
    repo_dir="$(dirname "$git_dir")"
    repo_name="$(basename "$repo_dir")"

    result=$(git -C "$repo_dir" fetch --all --prune 2>&1)
    if [[ $? -eq 0 ]]; then
        echo "  ✓ $repo_name" >> "$LOG_FILE"
    else
        echo "  ✗ $repo_name: $result" >> "$LOG_FILE"
    fi
done

echo "" >> "$LOG_FILE"
