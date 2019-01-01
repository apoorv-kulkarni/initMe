###########
#On my terms bro
###########
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

###########
# Increase command history because... source : https://apple.stackexchange.com/questions/246621/cant-increase-mac-osx-bash-shell-history-length
###########
export HISTFILESIZE=1000000
export HISTSIZE=1000000 

###########
#brew_stuff
###########
export PATH="/usr/local/bin:${PATH}"

###########
#Aliases
###########
alias ls='ls -GFh'

###########
#GPG_TTY nonsense
###########
export GPG_TTY=$(tty)


# Add Visual Studio Code (code) just in case
export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"