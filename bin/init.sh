#!/bin/zsh

# This script is the first step of setup

# Install base tools
## Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## Git
brew install git

## Xcode
xcode-select --install

# Clone my dotfiles
#   1. Setup of 1Password for SSH Auth
#   2. Setup of SSH (only 1Password's SSH agent)
#   3. Clone dotfiles repo with dotfiles-private repo
#   5. Setup of SSH (full)
read STDIN'?Please setup 1Password. If you complete to setup. -> [ENTER]: '
mkdir $HOME/.ssh
cat <<EOF
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF > $HOME/.ssh/config
mkdir -p $HOME/workspaces/github.com/yyh-gl
git clone --recurse-submodules git@github.com:yyh-gl/dotfiles.git $HOME/workspaces/github.com/yyh-gl/dotfiles
rm -rf $HOME/.ssh
ln -s $HOME/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.ssh $HOME/

## Google Drive
read STDIN'?Please setup Google Drive. If you complete to setup. -> [ENTER]: '
mkdir $HOME/Desktop/hobby
