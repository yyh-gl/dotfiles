#!/bin/zsh

# This script is the first step of setup

# Setup for Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Setup for 1Password
brew install --cask 1password
echo 'Please setup 1Password.'
read -r STDIN'?First, please sign in. [ENTER]: '
read -r STDIN'?Second, please enable SSH Agent. [ENTER]: '
read -r STDIN'?Last, please add "ssh-keys" to .config/1Password/ssh/agent.toml as needed. [ENTER]: '

# Setup for Git
brew install git

## Set temporary SSH config
mkdir -p "$HOME"/.ssh
cat <<EOF > "$HOME"/.ssh/config
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF

# Setup for Xcode
if [ -d /Library/Developer/CommandLineTools ]; then
  echo "Skip Xcode installation"
else
  sudo rm -rf /Library/Developer/CommandLineTools
  sudo xcode-select --install
  read -r STDIN'?Please setup Xcode. [ENTER]: '
  sudo xcodebuild -license accept
fi

# Clone my dotfiles
mkdir -p "$HOME"/workspaces/github.com/yyh-gl/config
git clone --recurse-submodules git@github.com:yyh-gl/dotfiles.git "$HOME"/workspaces/github.com/yyh-gl/dotfiles

echo "Go to cloned dotfiles directory and run 'make build'."
