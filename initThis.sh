#!/bin/bash

###Get Brew first
$ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
mv .bash_profile ~/.bash_profile && source ~/.bash_profile

#install Command Line Tools in Mac OS X
xcode-select --install;

## Necessary brew things that I think are needed
brew install git;
brew install gpg2;
brew install node;
easy_install pip;

### Git config, purposefully commented out
#git config --global user.name "FN LN"
#git config --global user.email "<email@email.com>"
#git config --global user.signingkey <id>


# Feed this do while loop a list of vscode extensions to install on vs code; 
# no sync nonsense because security is paramount

# note to self: before you migrate to a different machine, 
# please `run code --list-extensions` on old device's terminal 
# and then update this file vscode-extensions-list.txt if necessary

while read p; do code --install-extension $p; done <vscode-extensions-list.txt 