# Dotfiles

## Setup

1. Install Homebrew
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. Setup for 1Password
    1. Sign in
    2. Enable SSH Agent
3. Install Git
   ```sh
   brew install git
   ```
4. Setup fot SSH (temporary)
   ```sh
   mkdir "$HOME"/.ssh
   cat <<EOF > "$HOME"/.ssh/config
   Host *
   IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
   EOF
   ```
5. Clone my dotfiles
   ```sh
   mkdir -p "$HOME"/workspaces/github.com/yyh-gl/config
   git clone --recurse-submodules git@github.com:yyh-gl/dotfiles.git "$HOME"/workspaces/github.com/yyh-gl/config/dotfiles
   ```
6. Customize the environment variables in `.env`
    - `MODE`: Set to either "hobby" or "work"
        - hobby: for personal
        - work: for company job
    - `GO_VERSION`: Go version to install
    - `JVM_VERSION`: JVM version to install
7. Run setup command
   ```sh
   make build
   ```

## Repository Structure

- `.env`: Environment variables used by the Makefile
- `.brewfile-base`, `.brewfile-hobby`: Homebrew package lists for installing software
- `.defaults`: macOS system defaults configuration
- `.gh-config`: GitHub CLI configuration
- `.git-config`: Git configuration files
- `.karabiner`: Karabiner Elements keyboard customization settings
- `.rectangle-config.json`: Rectangle window manager configuration
- `.iterm2-profiles.json`: iTerm2 terminal emulator profiles
- `.zshrc`, `.zshenv`, `.zprofile`, `.zpreztorc`, `.zshlogin`, `.zshlogout`, etc.: Zsh shell
  configuration files
- `bin/`: Directory containing utility scripts
- `depended-repositories/`: External repositories this project depends on

## Installation and Setup

The repository includes several scripts and a Makefile to help with installation:

- `bin/init.sh`: Initial setup script for installing base tools (Homebrew, Git, Xcode) and cloning
  repositories
- `bin/link.sh`: Creates symbolic links for dotfiles and configuration files
- `bin/brew.sh`: Installs packages using Homebrew from `.Brewfile-base` and optionally
  `.Brewfile-hobby`
- `bin/defaults.sh`: Configures macOS system defaults like keyboard and trackpad settings
- `bin/mas.sh`: Installs Mac App Store applications using mas-cli
- `bin/go.sh`: Installs Go with the specified version
- `bin/jvm.sh`: Installs JVM with the specified version
- `bin/manual.sh`: Final setup steps including manual setup

To set up the dotfiles, you can use the Makefile which provides various targets for installation and
configuration.

## Usage

1. Clone this repository with submodules
2. Run the appropriate installation commands (likely using the Makefile)
3. The dotfiles will be symlinked to your home directory
4. Restart your terminal or reload configurations to apply changes
