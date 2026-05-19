# Dotfiles

## Setup

```sh
make init
make build-hobby  # or make build-work
```

> [!NOTE]
> Run `make init` only once at the beginning

## Repository Structure

- `.brewfile-base`, `.brewfile-hobby`: Homebrew package lists for installing software
- `.defaults`: macOS system defaults configuration
- `.git-config`: Git configuration files
- `.karabiner`: Karabiner Elements keyboard customization settings
- `.rectangle-config.json`: Rectangle window manager configuration
- `.iterm2-profiles.json`: iTerm2 terminal emulator profiles
- `.zshrc`, `.zshenv`, `.zprofile`, `.zpreztorc`, etc.: Zsh shell configuration files
- `bin/`: Directory containing utility scripts for setup and initialization
- `nix/`: Nix configuration (nix-darwin + home-manager)
- `scripts/`: Utility shell scripts (added to PATH)

## Installation and Setup

The repository includes several scripts and a Makefile to help with installation:

- `bin/init.sh`: Initial setup script for installing base tools (Homebrew, Git, Xcode, 1Password) and cloning repositories
- `bin/install-nix.sh`: Installs Nix package manager
- `bin/manual.sh`: Final setup steps including manual setup
- `bin/brew.sh`: Installs packages using Homebrew from `.Brewfile-base` and optionally `.Brewfile-hobby`
- `bin/defaults.sh`: Configures macOS system defaults like keyboard and trackpad settings

To set up the dotfiles, you can use the Makefile which provides various targets for installation and
configuration.

## Usage

1. Clone this repository: `git clone git@github.com:yyh-gl/dotfiles.git`
2. Run `make init` (first time only)
3. Run `make build-hobby` or `make build-work`
