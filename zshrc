# =============================================================================
# ~/.zshrc
# =============================================================================

# Enable Powerlevel10k instant prompt. Must stay close to the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -----------------------------------------------------------------------------
# oh-my-zsh
# -----------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins — cloned to ~/.oh-my-zsh/custom/plugins/ by bootstrap.sh / bootstrap-pi.sh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Docker CLI completions — must be added to fpath before oh-my-zsh calls compinit
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

source "$ZSH/oh-my-zsh.sh"

# -----------------------------------------------------------------------------
# PATH
# -----------------------------------------------------------------------------
export PATH="/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$PATH"

# VS Code CLI (macOS only)
[[ -d "/Applications/Visual Studio Code.app" ]] && \
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# krew (kubectl plugin manager)
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# -----------------------------------------------------------------------------
# pyenv
# -----------------------------------------------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
[[ -x "$PYENV_ROOT/bin/pyenv" ]] && eval "$(pyenv init -)"

# -----------------------------------------------------------------------------
# Go
# -----------------------------------------------------------------------------
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:$GOBIN"

# -----------------------------------------------------------------------------
# .NET (macOS / Homebrew only)
# -----------------------------------------------------------------------------
_DOTNET_ROOT="${HOMEBREW_PREFIX:-/usr/local}/opt/dotnet@9/libexec"
if [[ -d "$_DOTNET_ROOT" ]]; then
    export DOTNET_ROOT="$_DOTNET_ROOT"
    export PATH="$DOTNET_ROOT:$PATH"
fi
unset _DOTNET_ROOT

# -----------------------------------------------------------------------------
# History
# -----------------------------------------------------------------------------
export HISTFILESIZE=1000000
export HISTSIZE=1000000
setopt HIST_IGNORE_DUPS     # don't record duplicate commands
setopt HIST_IGNORE_SPACE    # don't record commands starting with a space
setopt SHARE_HISTORY        # share history across all open terminals

# -----------------------------------------------------------------------------
# GPG & editor
# -----------------------------------------------------------------------------
export GPG_TTY=$TTY
export EDITOR=vim

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
if [[ "$(uname)" == "Darwin" ]]; then
    alias ls='ls -GFh'
else
    alias ls='ls --color=auto -Fh'
fi
alias ll='ls -lah'
alias grep='grep --color=auto'

# kubernetes
alias k='kubectl'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

# Generate a random 32-character alphanumeric string
random-string() {
  LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1
}

# Generate one or more UUIDs (lowercase)
# Usage: uuid [count]
uuid() {
  local count="${1:-1}"
  for ((i=1; i<=count; i++)); do
    uuidgen | tr '[:upper:]' '[:lower:]'
  done
}
alias uuid1='uuid 1'

# -----------------------------------------------------------------------------
# Powerlevel10k config — run 'p10k configure' to regenerate
# -----------------------------------------------------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
