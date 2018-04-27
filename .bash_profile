###########
#On my terms bro
###########
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

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