#!/bin/bash
set -euo pipefail

# =============================================================================
# initThis.sh — new machine setup script
# Run from the repo root: bash initThis.sh
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Xcode Command Line Tools
# -----------------------------------------------------------------------------
echo "Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo ""
    echo "A dialog has opened to install the Xcode CLT."
    echo "Please complete that install, then re-run this script."
    exit 0
fi
echo "  Xcode CLT already installed."

# -----------------------------------------------------------------------------
# 2. Homebrew
# -----------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew (you may be asked for your sudo password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Set up Homebrew in PATH for this session (handles Apple Silicon + Intel)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" || true
echo "  Homebrew ready at: $(brew --prefix)"

# -----------------------------------------------------------------------------
# 3. Packages — brew bundle (see Brewfile)
# -----------------------------------------------------------------------------
echo "Installing packages from Brewfile..."
brew bundle

# -----------------------------------------------------------------------------
# 4. Terraform (via tfenv)
# -----------------------------------------------------------------------------
if ! tfenv list | grep -q '[0-9]'; then
    echo "Installing latest Terraform via tfenv..."
    tfenv install latest
    tfenv use latest
fi
echo "  Terraform: $(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1)"

# -----------------------------------------------------------------------------
# 5. Python (via pyenv)
# -----------------------------------------------------------------------------
if [[ -z "$(pyenv versions --bare 2>/dev/null)" ]]; then
    echo "Installing latest stable Python via pyenv..."
    LATEST_PYTHON=$(pyenv install --list | grep -E '^\s+3\.[0-9]+\.[0-9]+$' | grep -v 'dev\|rc\|alpha\|beta' | tail -1 | tr -d ' ')
    pyenv install "$LATEST_PYTHON"
    pyenv global "$LATEST_PYTHON"
    echo "  Python $LATEST_PYTHON set as global"
fi

# -----------------------------------------------------------------------------
# 6. SSH key
# -----------------------------------------------------------------------------
if [[ ! -f "$HOME/.ssh/id_ed25519" && ! -f "$HOME/.ssh/id_rsa" ]]; then
    echo ""
    echo "No SSH key found. Generating one now."
    read -rp "  Email for SSH key: " ssh_email
    ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
    echo ""
    echo "  Your public key (add this to GitHub → Settings → SSH keys):"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    read -rp "  Press Enter once you've added it to GitHub..." _
else
    echo "  SSH key already exists, skipping."
fi

# -----------------------------------------------------------------------------
# 7. GitHub CLI auth
# -----------------------------------------------------------------------------
if ! gh auth status &>/dev/null; then
    echo "Authenticating GitHub CLI..."
    gh auth login
else
    echo "  GitHub CLI already authenticated."
fi

# -----------------------------------------------------------------------------
# 8. oh-my-zsh
# -----------------------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "  oh-my-zsh already installed."
fi

# -----------------------------------------------------------------------------
# 9. Powerlevel10k theme
# -----------------------------------------------------------------------------
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "  Powerlevel10k already installed."
fi

# -----------------------------------------------------------------------------
# 10. zshrc
# -----------------------------------------------------------------------------
echo "Copying zshrc..."
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    echo "  Backed up existing .zshrc to ~/.zshrc.bak"
fi
cp zshrc "$HOME/.zshrc"

# -----------------------------------------------------------------------------
# 11. macOS defaults
# -----------------------------------------------------------------------------
echo "Applying macOS defaults..."

# Finder: show file extensions and hidden files
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true

# Faster key repeat (lower = faster; default is 6/2)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Save screenshots to ~/Desktop/Screenshots
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location "$HOME/Desktop/Screenshots"

# Dock: auto-hide, remove delay
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0

# Restart Finder and Dock to apply changes
killall Finder
killall Dock

echo "  macOS defaults applied."

# -----------------------------------------------------------------------------
# 12. Repo sync — launchd agent (macOS only, runs every 6 hours)
# -----------------------------------------------------------------------------
PLIST_LABEL="com.apoorv.sync-repos"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
SYNC_SCRIPT="$(pwd)/sync-repos.sh"

chmod +x "$SYNC_SCRIPT"

if [[ ! -f "$PLIST_PATH" ]]; then
    echo "Installing launchd agent for repo sync..."
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SYNC_SCRIPT</string>
    </array>
    <key>StartInterval</key>
    <integer>21600</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/logs/sync-repos-launchd.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/logs/sync-repos-launchd.log</string>
</dict>
</plist>
EOF
    launchctl load "$PLIST_PATH"
    echo "  Repo sync scheduled every 6 hours. Logs: ~/logs/sync-repos.log"
    echo ""
    echo "  On Raspberry Pi / Linux, add to crontab instead:"
    echo "    crontab -e"
    echo "    0 */6 * * * /bin/bash \$HOME/myLab/initMe/sync-repos.sh"
else
    echo "  Repo sync launchd agent already installed."
fi

# -----------------------------------------------------------------------------
# 14. Git config — fill in before running, then uncomment
# -----------------------------------------------------------------------------
# git config --global user.name "First Last"
# git config --global user.email "you@example.com"
# git config --global user.signingkey <gpg-key-id>
# git config --global commit.gpgsign true

# -----------------------------------------------------------------------------
# 15. VS Code extensions
# -----------------------------------------------------------------------------
echo "Installing VS Code extensions..."
if command -v code &>/dev/null; then
    while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        code --install-extension "$ext"
    done < vscode-extensions-list.txt
else
    echo "  Warning: 'code' command not found."
    echo "  After launching VS Code once, run:"
    echo "    while IFS= read -r ext; do code --install-extension \"\$ext\"; done < vscode-extensions-list.txt"
fi

# -----------------------------------------------------------------------------
echo ""
echo "Done! Next steps:"
echo "  1. Open a new terminal — all shell settings take effect"
echo "  2. Run 'p10k configure' to set up your prompt style"
echo "     (or copy your .p10k.zsh from your old machine to skip this)"
echo "  3. Fill in and uncomment the git config section in this script"
