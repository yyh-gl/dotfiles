#!/bin/zsh

# This script is the final step of setup

echo '[Finder] Sort items in side bar (root, Desktop, Downloads, Pictures, Documents, Applications, AirDrop)'
echo '[JetBrains ToolBox] Log in with a personal account and authenticate the license with a code (to inherit the settings of the personal account)'
echo '[Google 日本語入力] Import user dictionary file (1Password) and change space to half-width'
echo '[Tailscale] Set ACL tags for this machine'
echo '[sbx] Run `sbx login`, then register Anthropic credentials with `sbx secret rm anthropic; sbx secret set-custom --host api.anthropic.com --env ANTHROPIC_OAUTH_TOKEN --placeholder "sk-ant-oat01-{rand}"` (see docs.docker.com/ai/sandboxes/get-started/configuration/credentials/). Only needed once; sandboxes persist afterward'
