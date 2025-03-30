# Dotfiles

## Setup

1. Customize the environment variables in `.env`:
   - `MODE`: Set to either "hobby" or "work"
     - hobby: for personal
     - work: for company job
   - `GO_VERSION`: Go version to install
   - `JVM_VERSION`: JVM version to install

2. Run one of the following commands:
   - `make build`: Setup for macOS
   - `make build-go`: Install Go with the version specified in .env
   - `make build-jvm`: Install JVM with the version specified in .env

## Repository Structure
- `.env`: Environment variables used by the Makefile
- `.brewfile-base`, `.brewfile-hobby`: Homebrew package lists for installing software
- `.defaults`: macOS system defaults configuration
- `.gh-config`: GitHub CLI configuration
- `.git-config`: Git configuration files
- `.karabiner`: Karabiner Elements keyboard customization settings
- `.rectangle-config.json`: Rectangle window manager configuration
- `.iterm2-profiles.json`: iTerm2 terminal emulator profiles
- `.zshrc`, `.zshenv`, `.zprofile`, `.zpreztorc`, `.zshlogin`, `.zshlogout`, etc.: Zsh shell configuration files
- `bin/`: Directory containing utility scripts
- `depended-repositories/`: External repositories this project depends on

## Installation and Setup
The repository includes several scripts and a Makefile to help with installation:
- `bin/init.sh`: Initial setup script for installing base tools (Homebrew, Git, Xcode) and cloning repositories
- `bin/link.sh`: Creates symbolic links for dotfiles and configuration files
- `bin/brew.sh`: Installs packages using Homebrew from `.Brewfile-base` and optionally `.Brewfile-hobby`
- `bin/defaults.sh`: Configures macOS system defaults like keyboard and trackpad settings
- `bin/mas.sh`: Installs Mac App Store applications using mas-cli
- `bin/go.sh`: Installs Go with the specified version
- `bin/jvm.sh`: Installs JVM with the specified version
- `bin/manual.sh`: Final setup steps including manual setup

To set up the dotfiles, you can use the Makefile which provides various targets for installation and configuration.

## Usage
1. Clone this repository with submodules
2. Run the appropriate installation commands (likely using the Makefile)
3. The dotfiles will be symlinked to your home directory
4. Restart your terminal or reload configurations to apply changes
