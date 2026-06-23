#!/usr/bin/env bash
# Clone repos that make up Apoorv's ~/myLab workspace.
# Run once on a new machine after initMe is on disk (or let this script clone initMe too).
#
# Usage:
#   clone-mylab                  # clone into ~/myLab/
#   clone-mylab /path/to/dir     # clone into a custom directory
set -euo pipefail

MYLAB_DIR="${1:-$HOME/myLab}"
mkdir -p "$MYLAB_DIR"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

clone_if_missing() {
  local url="$1"
  local name
  name="$(basename "$url" .git)"
  local dest="$MYLAB_DIR/$name"

  if [[ -d "$dest/.git" ]]; then
    echo -e "${YELLOW}[skip]${NC} $name (already cloned)"
  elif [[ -d "$dest" ]]; then
    echo -e "${YELLOW}[skip]${NC} $name (directory exists without .git — e.g. tarball install)"
  else
    echo -e "${GREEN}[clone]${NC} $name"
    git clone "$url" "$dest"
  fi
}

# --- Bootstrap / machine setup (clone this first on a blank machine if needed) ---
clone_if_missing "git@github.com:apoorv-kulkarni/initMe.git"

# --- Active personal projects (repos you keep under ~/myLab today) ---
clone_if_missing "git@github.com:apoorv-kulkarni/apoorv-kulkarni.github.io.git"
clone_if_missing "git@github.com:apoorv-kulkarni/mechanical-watch-ui.git"
clone_if_missing "git@github.com:apoorv-kulkarni/trending-screensaver.git"
clone_if_missing "git@github.com:apoorv-kulkarni/vigiles.git"

# --- Third-party forks you track locally (optional) ---
clone_if_missing "https://github.com/jef/streetmerchant.git"
clone_if_missing "https://github.com/rdeepak2002/reddit-place-script-2022.git"

# --- Older / practice repos (uncomment any you still want under ~/myLab) ---
# clone_if_missing "git@github.com:apoorv-kulkarni/apoorv-kulkarni.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/cpp_practice.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/nodejsPractice.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/GoogleCommuteTime.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/urlChecker.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/leetcode.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/highCharts-SMM.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/nodeschool-javascript.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/NumbersToRomanNumeral.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/SonosController.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/python_practice.git"
# clone_if_missing "git@github.com:apoorv-kulkarni/GoLangExploration.git"

# --- Separate learning repo (not under ~/myLab; lives at ~/Personal_Practice/) ---
# mkdir -p "$HOME/Personal_Practice" && git clone <url> "$HOME/Personal_Practice/<name>"

echo ""
echo -e "${GREEN}Done.${NC} Workspace is at $MYLAB_DIR"
echo "Next: cd $MYLAB_DIR/initMe && bash install.sh   # symlink dotfiles + Cursor rules"
echo "       bash bootstrap.sh                         # full new-machine setup (macOS)"
