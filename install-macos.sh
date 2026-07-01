#!/usr/bin/env bash
# initMe macOS installer — paste on a fresh Mac (Homebrew-style entry point).
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)"
#
# Preview bootstrap without applying changes:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)" -- --dry-run
#
# Custom parent directory (installs to <dir>/initMe):
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/apoorv-kulkarni/initMe/HEAD/install-macos.sh)" -- "$HOME/code"
set -euo pipefail

OWNER="apoorv-kulkarni"
REPO="initMe"
# HEAD tarball follows the repo default branch (same idea as Homebrew's HEAD URLs).
TARBALL_URL="https://github.com/${OWNER}/${REPO}/archive/HEAD.tar.gz"

ohai()  { echo "==> $*"; }
warn()  { echo "Warning: $*" >&2; }
abort() { echo "initMe: $*" >&2; exit 1; }

# --- Parse args (path or bootstrap flags) ---
MYLAB_DIR="${HOME}/myLab"

# Drop an optional separator for bash -c "..." -- style invocations.
if [[ $# -gt 0 && "${1:-}" == "--" ]]; then
  shift
fi

# First non-flag arg is the parent install dir.
if [[ $# -gt 0 && "${1:0:1}" != "-" ]]; then
  MYLAB_DIR="$1"
  shift
fi

DEST="${MYLAB_DIR}/${REPO}"

# --- Preflight (Homebrew checks OS first) ---
ohai "Checking macOS"
[[ "$(uname -s)" == "Darwin" ]] || abort "This installer is for macOS. On Raspberry Pi / Linux, use git clone + bootstrap-pi.sh."

ohai "Checking curl"
command -v curl >/dev/null || abort "curl is required."

if [[ -d "$DEST/.git" ]]; then
  ohai "initMe is already installed at $DEST"
  echo "To update and re-run setup:"
  echo "  cd $DEST && git pull && bash bootstrap.sh"
  exit 0
fi

if [[ -e "$DEST" ]]; then
  abort "$DEST exists but is not a git clone. Move or remove it, then re-run."
fi

ohai "This script will:"
echo "  - Download ${OWNER}/${REPO} into ${DEST}"
echo "  - Run bootstrap.sh (Homebrew, shell, dotfiles, GitHub CLI, repo sync, ...)"
echo "  - Prompt for Xcode CLT, SSH key, and gh auth where needed"
echo ""

mkdir -p "$MYLAB_DIR"

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

ohai "Downloading ${OWNER}/${REPO}"
curl -fsSL "$TARBALL_URL" | tar -xz -C "$tmpdir"

# GitHub archive folder is initMe-<sha> or initMe-master depending on HEAD resolution
extracted="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -1)"
[[ -n "$extracted" && -d "$extracted" ]] || abort "Unexpected download layout."

mv "$extracted" "$DEST"
trap - EXIT
cleanup

ohai "Installed to $DEST"
warn "Tarball install has no .git yet; bootstrap.sh will convert it after GitHub auth."
echo ""

ohai "Running bootstrap.sh"
cd "$DEST"
exec bash bootstrap.sh "$@"
