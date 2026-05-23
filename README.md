# Dotfiles

## Setup

```sh
make init
make build-hobby  # or make build-work
```

> [!NOTE]
> Run `make init` only once at the beginning

## Repository Structure

- `bin/`: Setup scripts (`init.sh`, `install-nix.sh`, `manual.sh`)
- `nix/`: nix-darwin + home-manager configurations
  - `darwin/`: nix-darwin system settings (Homebrew, macOS defaults)
  - `home/`: home-manager configurations (zsh, dotfile deploy, packages, secrets)
- `claude/`: Claude Code configuration (settings, agents, skills, hooks)
- `op-templates/`: 1Password secret templates expanded by `op inject`
- `scripts/`: Utility shell scripts (added to `$PATH` via zsh)
- `aws/`, `.git-config/`, `.ssh/keys/`, `.defaults/`, `.emacs.d/`: Tool-specific configs deployed by home-manager
- `ghostty-config`, `karabiner.json`, `starship.toml`: Standalone tool configs deployed by home-manager

## Installation and Setup

- `bin/init.sh`: Initial setup script for installing base tools (Homebrew, 1Password, Git, Xcode) and cloning this repository
- `bin/install-nix.sh`: Installs the Nix package manager
- `bin/manual.sh`: Lists remaining manual steps (iTerm2 import, JetBrains login, etc.)

Refer to [`CLAUDE.md`](./CLAUDE.md) for details on the Nix setup, 1Password secrets management, and build modes.

## Usage

1. Clone this repository: `git clone git@github.com:yyh-gl/dotfiles.git`
2. Run `make init` (first time only)
3. Run `make build-hobby` or `make build-work`
