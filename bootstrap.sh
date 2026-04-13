#!/bin/bash
set -euo pipefail

# =============================================================================
# bootstrap.sh — new machine setup script
# Run from the repo root: bash bootstrap.sh
# =============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEP=0
TOTAL=16

step() {
    STEP=$((STEP + 1))
    echo ""
    echo "[$STEP/$TOTAL] $1"
}

# -----------------------------------------------------------------------------
# 1. Xcode Command Line Tools
# -----------------------------------------------------------------------------
step "Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
    echo "  Installing... (a dialog will open)"
    xcode-select --install
    echo ""
    echo "  Please complete the install dialog, then re-run this script."
    exit 0
fi
echo "  Already installed."

# -----------------------------------------------------------------------------
# 2. Homebrew
# -----------------------------------------------------------------------------
step "Homebrew"
if ! command -v brew &>/dev/null; then
    echo "  Installing (you may be asked for your sudo password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" || true
echo "  Ready at: $(brew --prefix)"

# -----------------------------------------------------------------------------
# 3. Packages — brew bundle
# -----------------------------------------------------------------------------
step "Packages (Brewfile)"
brew bundle --file="$REPO_DIR/Brewfile"

# -----------------------------------------------------------------------------
# 4. Terraform (via tfenv)
# -----------------------------------------------------------------------------
step "Terraform"
if ! tfenv list 2>/dev/null | grep -q '[0-9]'; then
    echo "  Installing latest Terraform via tfenv..."
    tfenv install latest
    tfenv use latest
fi
echo "  $(terraform version | head -1)"

# -----------------------------------------------------------------------------
# 5. Python (via pyenv)
# -----------------------------------------------------------------------------
step "Python"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
if [[ -z "$(pyenv versions --bare 2>/dev/null)" ]]; then
    echo "  Installing latest stable Python..."
    LATEST_PYTHON=$(pyenv install --list | grep -E '^\s+3\.[0-9]+\.[0-9]+$' | grep -v 'dev\|rc\|alpha\|beta' | tail -1 | tr -d ' ')
    pyenv install "$LATEST_PYTHON"
    pyenv global "$LATEST_PYTHON"
    echo "  Python $LATEST_PYTHON set as global"
else
    echo "  $(python3 --version) (managed by pyenv)"
fi

# -----------------------------------------------------------------------------
# 6. SSH key
# -----------------------------------------------------------------------------
step "SSH key"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$HOME/.ssh/id_ed25519" && ! -f "$HOME/.ssh/id_rsa" ]]; then
    echo "  No SSH key found. Generating a new ed25519 key."
    read -rp "  Email for SSH key: " ssh_email
    ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
    chmod 600 "$HOME/.ssh/id_ed25519"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"
    ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"
    echo ""
    echo "  Public key — add this to GitHub → Settings → SSH keys:"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    read -rp "  Press Enter once you've added it to GitHub..." _
else
    echo "  Key found. Setting permissions and loading into keychain..."
    chmod 600 "$HOME/.ssh/id_ed25519" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/id_rsa" 2>/dev/null || true
    chmod 644 "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || true
    chmod 644 "$HOME/.ssh/id_rsa.pub" 2>/dev/null || true
    KEY=""
    [[ -f "$HOME/.ssh/id_ed25519" ]] && KEY="$HOME/.ssh/id_ed25519"
    [[ -z "$KEY" && -f "$HOME/.ssh/id_rsa" ]] && KEY="$HOME/.ssh/id_rsa"
    ssh-add --apple-use-keychain "$KEY"
    echo "  Done."
fi

# -----------------------------------------------------------------------------
# 7. GitHub CLI auth
# -----------------------------------------------------------------------------
step "GitHub CLI"
if ! gh auth status &>/dev/null; then
    echo "  Authenticating..."
    gh auth login
else
    echo "  Already authenticated."
fi

# -----------------------------------------------------------------------------
# 8. oh-my-zsh
# -----------------------------------------------------------------------------
step "oh-my-zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "  Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "  Already installed."
fi

# -----------------------------------------------------------------------------
# 9. Powerlevel10k theme
# -----------------------------------------------------------------------------
step "Powerlevel10k"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "  Cloning..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "  Already installed."
fi

# -----------------------------------------------------------------------------
# 10. zsh plugins
# -----------------------------------------------------------------------------
step "zsh plugins"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
        echo "  Cloning $plugin..."
        git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin"
    else
        echo "  $plugin already installed."
    fi
done

# -----------------------------------------------------------------------------
# 11. zshrc — symlink so edits stay in sync with the repo
# -----------------------------------------------------------------------------
step "zshrc"
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    echo "  Backed up existing .zshrc to ~/.zshrc.bak"
fi
ln -sf "$REPO_DIR/zshrc" "$HOME/.zshrc"
echo "  Symlinked: ~/.zshrc -> $REPO_DIR/zshrc"
ln -sf "$REPO_DIR/p10k.zsh" "$HOME/.p10k.zsh"
echo "  Symlinked: ~/.p10k.zsh -> $REPO_DIR/p10k.zsh"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
ln -sf "$REPO_DIR/ssh_config" "$HOME/.ssh/config" && chmod 600 "$HOME/.ssh/config"
echo "  Symlinked: ~/.ssh/config -> $REPO_DIR/ssh_config"
git config --global core.excludesfile "$HOME/.gitignore_global"
ln -sf "$REPO_DIR/gitignore_global" "$HOME/.gitignore_global"
echo "  Symlinked: ~/.gitignore_global -> $REPO_DIR/gitignore_global"

# -----------------------------------------------------------------------------
# 12. macOS defaults
# -----------------------------------------------------------------------------
step "macOS defaults"
DEFAULTS_MARKER="$HOME/.config/initme/defaults_applied"
if [[ ! -f "$DEFAULTS_MARKER" ]]; then
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

    killall Finder
    killall Dock

    mkdir -p "$(dirname "$DEFAULTS_MARKER")"
    touch "$DEFAULTS_MARKER"
    echo "  Applied."
else
    echo "  Already applied (delete ~/.config/initme/defaults_applied to re-run)."
fi

# -----------------------------------------------------------------------------
# 13. Repo sync — launchd agent (runs every 6 hours)
# -----------------------------------------------------------------------------
step "Repo sync (launchd)"
PLIST_LABEL="com.apoorv.sync-repos"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
SYNC_SCRIPT="$REPO_DIR/sync-repos.sh"
chmod +x "$SYNC_SCRIPT"

if [[ ! -f "$PLIST_PATH" ]]; then
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
    echo "  Scheduled every 6 hours. Logs: ~/logs/sync-repos.log"
else
    echo "  Already installed."
fi

# -----------------------------------------------------------------------------
# 15. iTerm2 profile
# -----------------------------------------------------------------------------
step "iTerm2 profile"
if [[ -f "$REPO_DIR/iterm2_profile.plist" ]]; then
    defaults import com.googlecode.iterm2 "$REPO_DIR/iterm2_profile.plist"
    echo "  Imported. Restart iTerm2 to apply."
else
    echo "  No iterm2_profile.plist found, skipping."
fi

# -----------------------------------------------------------------------------
# 16. VS Code extensions
# -----------------------------------------------------------------------------
step "VS Code extensions"
if command -v code &>/dev/null; then
    while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        code --install-extension "$ext"
    done < "$REPO_DIR/vscode-extensions-list.txt"
else
    echo "  Warning: 'code' not found. After launching VS Code once, run:"
    echo "    while IFS= read -r ext; do code --install-extension \"\$ext\"; done < vscode-extensions-list.txt"
fi

# -----------------------------------------------------------------------------
# Git config
# -----------------------------------------------------------------------------
step "Git config"
if [[ -z "$(git config --global user.name 2>/dev/null)" ]]; then
    read -rp "  Git name: " git_name
    read -rp "  Git email: " git_email
    read -rp "  GPG signing key ID (leave blank to skip): " git_signingkey
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    if [[ -n "$git_signingkey" ]]; then
        git config --global user.signingkey "$git_signingkey"
        git config --global commit.gpgsign true
        git config --global gpg.program gpg
    fi
    echo "  Git config set."
else
    echo "  Already configured as: $(git config --global user.name) <$(git config --global user.email)>"
fi

# -----------------------------------------------------------------------------
echo ""
echo "All done! Next steps:"
echo "  1. Open a new terminal — all shell settings take effect"
echo "  2. Run 'p10k configure' to set up your prompt style"
echo "     (or copy your .p10k.zsh from your old machine to skip this)"
echo "  3. Fill in and uncomment the git config block at the bottom of bootstrap.sh"
