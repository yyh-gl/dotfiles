# Dotfiles Project Overview

## Introduction
This repository contains dotfiles and configuration files for various tools and applications. Dotfiles are configuration files in Unix-like systems that start with a dot (.) and are typically hidden in directory listings. This collection helps maintain consistent development environments across different machines.

## Setup
1. Customize the environment variables in the `.env` file if needed:
   - `MODE`: Set to either "work" or "hobby" (default: "hobby")
   - `GO_VERSION`: Go version to install (default: "1.24.2")
   - `JVM_VERSION`: JVM version to install (default: "24")

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

## Shell Configuration
This repository uses Zsh as the primary shell with configurations for:
- Environment variables (`.zshenv`)
- Login settings (`.zlogin`, `.zlogout`)
- Shell behavior (`.zshrc`)
- Prezto framework configuration (`.zpreztorc`)

## Installation and Setup
The repository includes several scripts and a Makefile to help with installation:
- `bin/init.sh`: Initial setup script for installing base tools (Homebrew, Git, Xcode) and cloning repositories
- `bin/link.sh`: Creates symbolic links for dotfiles and configuration files
- `bin/brew.sh`: Installs packages using Homebrew from .Brewfile-base and optionally .Brewfile-hobby
- `bin/defaults.sh`: Configures macOS system defaults like keyboard and trackpad settings
- `bin/mas.sh`: Installs Mac App Store applications using mas-cli
- `bin/manual.sh`: Final setup steps including manual configurations and Google Drive setup
- `bin/go.sh`: Installs Go with the specified version
- `bin/jvm.sh`: Installs JVM with the specified version

To set up the dotfiles, you can use the Makefile which provides various targets for installation and configuration.

## Usage
1. Clone this repository
2. Run the appropriate installation commands (likely using the Makefile)
3. The dotfiles will be symlinked to your home directory
4. Restart your terminal or reload configurations to apply changes

## Customization
You can customize these dotfiles by:
1. Modifying the existing files to suit your preferences
2. Adding new configuration files for additional tools
3. Updating the Brewfile to include your preferred software

## Maintenance
Regularly update this repository when you make changes to your configurations to ensure all your machines can be kept in sync.
