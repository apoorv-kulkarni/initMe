#!/bin/bash

#install Command Line Tools in Mac OS X
xcode-select --install;

###Get Brew first
if ! command -v brew >/dev/null 2>&1; then
    echo "You may be asked for your sudo password to install Homebrew:"
    sudo -v
    yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# force copy bash profile
echo "copying the bash profile"
mv .bash_profile ~/.bash_profile && source ~/.bash_profile;


############ Install cask ############
brew tap caskroom/cask

brew_apps=(
  git
  gpg2
  node
)

apps=(
  evernote
  firefox
  google-chrome
  iterm2
  vlc
  slack
  skype
  spotify
  visual-studio-code
)

## Necessary brew things that I think are needed
# Install apps to /Applications
# Default is /Users/$user/Applications
echo "installing brew apps for you..."
brew install  ${brew_apps[@]}
echo "installing apps like slack, spotify, vscode, chrome, ff, evernote, vlc, iterm2, skype for you..."
brew cask install --appdir="/Applications" ${apps[@]}

# brew cleanup 
brew cleanup

# for some reason this needs to be installed
easy_install pip;

##Git config, purposefully commented out
#git config --global user.name "FN LN"
#git config --global user.email "<email@email.com>"
#git config --global user.signingkey <id>


# Feed this do while loop a list of vscode extensions to install on vs code; 
# no sync nonsense because security is paramount

# note to self: before you migrate to a different machine, 
# please `run code --list-extensions` on old device's terminal 
# and then update this file vscode-extensions-list.txt if necessary

while read p; do code --install-extension $p; done <vscode-extensions-list.txt 