#!/bin/bash

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

MESSAGE="${1}"
AGENT_NAME="${2:-main}"

TITLE="${MESSAGE}"
BODY="${PROJECT_NAME} (${AGENT_NAME})"

source "$(dirname "${BASH_SOURCE[0]}")/lib/wezterm-tty.sh"

TTY_PATH="$(find_tty "$PPID")"

if [ -n "$TTY_PATH" ] && [ -w "$TTY_PATH" ]; then
  { printf '\e]777;notify;%s;%s\e\\' "$TITLE" "$BODY" > "$TTY_PATH"; } 2>/dev/null
fi

exit 0
