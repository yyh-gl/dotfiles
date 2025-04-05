#!/bin/zsh

# This script is the first step of setup

# Tools setup
## Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

## 1Password
brew install --cask 1password
echo 'Please setup 1Password.'
read -r STDIN'?First, please sign in. [ENTER]: '
read -r STDIN'?Last, please enable SSH Agent. [ENTER]: '

## Git
brew install git

### Set temporary SSH config
mkdir "$HOME"/.ssh
cat <<EOF > "$HOME"/.ssh/config
Host *
IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF

## Xcode
if [ -d /Library/Developer/CommandLineTools ]; then
  echo "Skip Xcode installation"
else
  sudo rm -rf /Library/Developer/CommandLineTools
  sudo xcode-select --install
  read -r STDIN'?Please setup Xcode. If you complete to setup. -> [ENTER]: '
  sudo xcodebuild -license accept
fi

# Clone my dotfiles
mkdir -p "$HOME"/workspaces/github.com/yyh-gl/config
git clone --recurse-submodules git@github.com:yyh-gl/dotfiles.git "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles

# Update .env
vi "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.env

# Setup for Zsh
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zlogin "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zlogout "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zpreztorc "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zprofile "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zshenv "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/.zshrc "$HOME"
mkdir "$HOME"/.zprezto
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/depended-repositories/prezto/init.zsh "$HOME"/.zprezto
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/depended-repositories/prezto/modules "$HOME"/.zprezto

# Setup for SSH
read -r STDIN'?Please setup 1Password. If you complete to setup. -> [ENTER]: '
rm -rf "$HOME"/.ssh
ln -s "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles/depended-repositories/dotfiles-private/.ssh "$HOME"
