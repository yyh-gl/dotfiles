#!/bin/zsh

# This script is the final step of setup

echo '[Finder] Sort items in side bar (root, Desktop, Downloads, Pictures, Documents, Applications, AirDrop)'
echo '[JetBrains ToolBox] Log in with a personal account and authenticate the license with a code (to inherit the settings of the personal account)'
echo '[Google 日本語入力] Import user dictionary file (1Password) and change space to half-width'
echo '[Tailscale] Set ACL tags for this machine'
echo '[sbx] Create a "OpenRouter" item in 1Password (vault PC, Secure Note, field id `api_key`), then run `op read "op://PC/OpenRouter/api_key" | sbx secret set openrouter` before the first `pi` run (credentials are fixed when the sandbox is created). Only needed once; sandboxes persist afterward'
