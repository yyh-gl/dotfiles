#!/bin/bash
set -euo pipefail

if command -v nix &>/dev/null; then
  echo "Nix is already installed: $(nix --version)"
  exit 0
fi

echo "Installing Nix (official multi-user)..."
sh <(curl -L https://nixos.org/nix/install) --daemon

mkdir -p ~/.config/nix
if ! grep -q 'experimental-features' ~/.config/nix/nix.conf 2>/dev/null; then
  echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
fi

echo "Nix installed. Continue with the first nix-darwin switch (make init-hobby / init-work does this); use make nix-apply-* only after that."
