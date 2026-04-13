#!/bin/bash
set -euo pipefail

# =============================================================================
# bootstrap-pi.sh — Raspberry Pi (Debian/Raspberry Pi OS) setup
# Run from the repo root: bash bootstrap-pi.sh [--dry-run]
# =============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
STEP=0
TOTAL=13

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true && echo "DRY RUN — previewing steps, no changes will be made"

run() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

step() {
    STEP=$((STEP + 1))
    echo ""
    echo "[$STEP/$TOTAL] $1"
}

# -----------------------------------------------------------------------------
# 1. Core apt packages
# -----------------------------------------------------------------------------
step "Core packages (apt)"
if ! $DRY_RUN; then
    sudo apt-get update -qq
    sudo apt-get install -y \
        git \
        gnupg \
        curl \
        wget \
        tree \
        jq \
        ripgrep \
        zsh \
        vim \
        build-essential \
        libssl-dev \
        libffi-dev \
        python3-dev
else
    echo "  [dry-run] would run: apt-get install git gnupg curl wget tree jq ripgrep zsh vim build-essential ..."
fi

# -----------------------------------------------------------------------------
# 2. GitHub CLI
# -----------------------------------------------------------------------------
step "GitHub CLI"
if ! command -v gh &>/dev/null; then
    echo "  Installing..."
    if ! $DRY_RUN; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update -qq && sudo apt-get install -y gh
    else
        echo "  [dry-run] would add GitHub CLI apt repo and install gh"
    fi
else
    echo "  Already installed: $(gh --version | head -1)"
fi

# -----------------------------------------------------------------------------
# 3. Go
# -----------------------------------------------------------------------------
step "Go"
if ! command -v go &>/dev/null; then
    echo "  Fetching latest Go for $ARCH..."
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
    case "$ARCH" in
        arm64|aarch64) GO_ARCH="arm64" ;;
        armhf|armv7l)  GO_ARCH="armv6l" ;;
        amd64|x86_64)  GO_ARCH="amd64" ;;
        *)             echo "  Unknown arch: $ARCH — skipping Go install"; GO_ARCH="" ;;
    esac
    if [[ -n "$GO_ARCH" ]]; then
        if ! $DRY_RUN; then
            curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf /tmp/go.tar.gz
            rm /tmp/go.tar.gz
            export PATH="/usr/local/go/bin:$PATH"
            echo "  Installed: $(go version)"
        else
            echo "  [dry-run] would install ${GO_VERSION} for ${GO_ARCH}"
        fi
    fi
else
    echo "  Already installed: $(go version)"
fi

# -----------------------------------------------------------------------------
# 4. pyenv + Python
# -----------------------------------------------------------------------------
step "Python (pyenv)"
export PYENV_ROOT="$HOME/.pyenv"
if [[ ! -d "$PYENV_ROOT" ]]; then
    echo "  Installing pyenv..."
    if ! $DRY_RUN; then
        curl -fsSL https://pyenv.run | bash
    else
        echo "  [dry-run] would install pyenv via pyenv.run"
    fi
fi
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if [[ -z "$(pyenv versions --bare 2>/dev/null)" ]]; then
    echo "  Installing latest stable Python..."
    LATEST_PYTHON=$(pyenv install --list | grep -E '^\s+3\.[0-9]+\.[0-9]+$' | grep -v 'dev\|rc\|alpha\|beta' | tail -1 | tr -d ' ')
    run pyenv install "$LATEST_PYTHON"
    run pyenv global "$LATEST_PYTHON"
    echo "  Python $LATEST_PYTHON set as global"
else
    echo "  $(python3 --version) (managed by pyenv)"
fi

# -----------------------------------------------------------------------------
# 5. Terraform (tfenv)
# -----------------------------------------------------------------------------
step "Terraform (tfenv)"
if [[ ! -d "$HOME/.tfenv" ]]; then
    echo "  Cloning tfenv..."
    run git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
fi
export PATH="$HOME/.tfenv/bin:$PATH"

if ! tfenv list 2>/dev/null | grep -q '[0-9]'; then
    echo "  Installing latest Terraform..."
    run tfenv install latest
    run tfenv use latest
fi
$DRY_RUN || echo "  $(terraform version | head -1)"

# -----------------------------------------------------------------------------
# 6. kubectl
# -----------------------------------------------------------------------------
step "kubectl"
if ! command -v kubectl &>/dev/null; then
    echo "  Installing..."
    K8S_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
    case "$ARCH" in
        arm64|aarch64) K8S_ARCH="arm64" ;;
        armhf|armv7l)  K8S_ARCH="arm" ;;
        amd64|x86_64)  K8S_ARCH="amd64" ;;
    esac
    if ! $DRY_RUN; then
        curl -fsSL "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/${K8S_ARCH}/kubectl" -o /tmp/kubectl
        sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
        rm /tmp/kubectl
        echo "  Installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    else
        echo "  [dry-run] would install kubectl ${K8S_VERSION} for ${K8S_ARCH}"
    fi
else
    echo "  Already installed: $(kubectl version --client --short 2>/dev/null || true)"
fi

# -----------------------------------------------------------------------------
# 7. kubectx
# -----------------------------------------------------------------------------
step "kubectx"
if ! command -v kubectx &>/dev/null; then
    echo "  Installing..."
    if ! $DRY_RUN; then
        sudo git clone --depth=1 https://github.com/ahmetb/kubectx /opt/kubectx
        sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
        sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
    else
        echo "  [dry-run] would clone kubectx to /opt/kubectx and symlink binaries"
    fi
else
    echo "  Already installed."
fi

# -----------------------------------------------------------------------------
# 8. k9s
# -----------------------------------------------------------------------------
step "k9s"
if ! command -v k9s &>/dev/null; then
    echo "  Installing..."
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
    case "$ARCH" in
        arm64|aarch64) K9S_ARCH="arm64" ;;
        armhf|armv7l)  K9S_ARCH="arm" ;;
        amd64|x86_64)  K9S_ARCH="amd64" ;;
    esac
    if ! $DRY_RUN; then
        curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${K9S_ARCH}.tar.gz" \
            | tar -xz -C /tmp k9s
        sudo mv /tmp/k9s /usr/local/bin/k9s
        echo "  Installed: $(k9s version --short 2>/dev/null | head -1)"
    else
        echo "  [dry-run] would install k9s ${K9S_VERSION} for ${K9S_ARCH}"
    fi
else
    echo "  Already installed."
fi

# -----------------------------------------------------------------------------
# 9. yq
# -----------------------------------------------------------------------------
step "yq"
if ! command -v yq &>/dev/null; then
    echo "  Installing..."
    YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name)
    case "$ARCH" in
        arm64|aarch64) YQ_ARCH="arm64" ;;
        armhf|armv7l)  YQ_ARCH="arm" ;;
        amd64|x86_64)  YQ_ARCH="amd64" ;;
    esac
    if ! $DRY_RUN; then
        curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH}" -o /tmp/yq
        sudo install -m 0755 /tmp/yq /usr/local/bin/yq
        rm /tmp/yq
        echo "  Installed: $(yq --version)"
    else
        echo "  [dry-run] would install yq ${YQ_VERSION} for ${YQ_ARCH}"
    fi
else
    echo "  Already installed: $(yq --version)"
fi

# -----------------------------------------------------------------------------
# 10. SSH key
# -----------------------------------------------------------------------------
step "SSH key"
run mkdir -p "$HOME/.ssh"
run chmod 700 "$HOME/.ssh"

if [[ ! -f "$HOME/.ssh/id_ed25519" && ! -f "$HOME/.ssh/id_rsa" ]]; then
    echo "  No SSH key found. Generating a new ed25519 key."
    if ! $DRY_RUN; then
        read -rp "  Email for SSH key: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
        chmod 600 "$HOME/.ssh/id_ed25519"
        chmod 644 "$HOME/.ssh/id_ed25519.pub"
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
        echo ""
        echo "  Public key — add this to GitHub → Settings → SSH keys:"
        echo ""
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""
        read -rp "  Press Enter once you've added it to GitHub..." _
    else
        echo "  [dry-run] would generate ed25519 key"
    fi
else
    echo "  Key found. Setting permissions..."
    run chmod 600 "$HOME/.ssh/id_ed25519" 2>/dev/null || true
    run chmod 600 "$HOME/.ssh/id_rsa" 2>/dev/null || true
    run chmod 644 "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || true
    run chmod 644 "$HOME/.ssh/id_rsa.pub" 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 11. oh-my-zsh + Powerlevel10k + plugins
# -----------------------------------------------------------------------------
step "oh-my-zsh + Powerlevel10k + plugins"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "  Installing oh-my-zsh..."
    run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
else
    echo "  oh-my-zsh already installed."
fi

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    echo "  Cloning Powerlevel10k..."
    run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "  Powerlevel10k already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
        echo "  Cloning $plugin..."
        run git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin"
    else
        echo "  $plugin already installed."
    fi
done

# -----------------------------------------------------------------------------
# 12. zshrc — symlink
# -----------------------------------------------------------------------------
step "zshrc"
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    run cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    echo "  Backed up existing .zshrc to ~/.zshrc.bak"
fi
run ln -sf "$REPO_DIR/zshrc" "$HOME/.zshrc"
echo "  Symlinked: ~/.zshrc -> $REPO_DIR/zshrc"
run ln -sf "$REPO_DIR/p10k.zsh" "$HOME/.p10k.zsh"
echo "  Symlinked: ~/.p10k.zsh -> $REPO_DIR/p10k.zsh"
run mkdir -p "$HOME/.ssh" && run chmod 700 "$HOME/.ssh"
run ln -sf "$REPO_DIR/ssh_config" "$HOME/.ssh/config" && run chmod 600 "$HOME/.ssh/config"
echo "  Symlinked: ~/.ssh/config -> $REPO_DIR/ssh_config"
run git config --global core.excludesfile "$HOME/.gitignore_global"
run ln -sf "$REPO_DIR/gitignore_global" "$HOME/.gitignore_global"
echo "  Symlinked: ~/.gitignore_global -> $REPO_DIR/gitignore_global"

# Set zsh as default shell if it isn't already
if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo "  Setting zsh as default shell..."
    run chsh -s "$(which zsh)"
fi

# -----------------------------------------------------------------------------
# 13. Repo sync (cron)
# -----------------------------------------------------------------------------
step "Repo sync (cron)"
SYNC_SCRIPT="$REPO_DIR/sync-repos.sh"
run chmod +x "$SYNC_SCRIPT"
CRON_JOB="0 */6 * * * /bin/bash $SYNC_SCRIPT"

if ! crontab -l 2>/dev/null | grep -qF "sync-repos.sh"; then
    if ! $DRY_RUN; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "  Added to crontab (every 6 hours)."
    else
        echo "  [dry-run] would add to crontab: $CRON_JOB"
    fi
else
    echo "  Already in crontab."
fi

# -----------------------------------------------------------------------------
# Git config
# -----------------------------------------------------------------------------
step "Git config"
if [[ -z "$(git config --global user.name 2>/dev/null)" ]]; then
    if ! $DRY_RUN; then
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
        echo "  [dry-run] would prompt for git name, email, and optional GPG signing key"
    fi
else
    echo "  Already configured as: $(git config --global user.name) <$(git config --global user.email)>"
fi

# -----------------------------------------------------------------------------
echo ""
echo "All done! Next steps:"
echo "  1. Log out and back in (or run: exec zsh) to use zsh"
echo "  2. Run 'p10k configure' to set up your prompt style"
echo "  3. Authenticate GitHub CLI: gh auth login"
