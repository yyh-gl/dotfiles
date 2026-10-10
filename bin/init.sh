#!/bin/zsh

# This script is the first step of setup (run by `make init-hobby` / `make init-work`).
# It assumes Xcode Command Line Tools are installed and this repository is already cloned.

setopt err_exit pipe_fail no_unset

# Setup for Homebrew
if [[ ! -x /opt/homebrew/bin/brew ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Apple Silicon用のHomebrewはPATHに自動では入らない
eval "$(/opt/homebrew/bin/brew shellenv)"

# Setup for 1Password
if [[ ! -d "/Applications/1Password.app" ]]; then
  brew install --cask 1password
fi
echo 'Please setup 1Password.'
read -r STDIN'?First, please sign in. [ENTER]: '
read -r STDIN'?Second, please enable SSH Agent and CLI integration. [ENTER]: '
read -r STDIN'?Last, please add "ssh-keys" to .config/1Password/ssh/agent.toml as needed. [ENTER]: '

## Set temporary SSH config
mkdir -p "$HOME"/.ssh
if [[ ! -e "$HOME"/.ssh/config ]]; then
  cat <<'SSH_EOF' > "$HOME"/.ssh/config
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
SSH_EOF
fi

# Setup for Xcode
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  read -r STDIN'?Please finish installing Command Line Tools. [ENTER]: '
fi
# ライセンス同意はXcode本体がある場合だけ必要（Command Line Toolsだけなら不要）
if [[ -d /Applications/Xcode.app ]]; then
  sudo xcodebuild -license accept
fi

echo "Done. If you cloned over HTTPS, switch the remote to SSH: git remote set-url origin git@github.com:yyh-gl/dotfiles.git"
