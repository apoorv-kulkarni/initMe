#!/bin/bash

# Feed this do while loop a list of vscode extensions to install on vs code; 
# no sync nonsense because security is paramount

# note to self: before you migrate to a different machine, 
# please `run code --list-extensions` on old device's terminal 
# and then update this file vscode-extensions-list.txt if necessary

while read p; do code --install-extension $p; done <vscode-extensions-list.txt 