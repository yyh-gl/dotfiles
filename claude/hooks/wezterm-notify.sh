#!/bin/bash

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

MESSAGE="${1}"
AGENT_NAME="${2:-main}"

# OSC 777は`;`でフィールドを区切り、ESCで終端する。ディレクトリ名などに含まれる制御文字と`;`を落として、
# フィールドのずれやエスケープシーケンスの注入を防ぐ
sanitize() { printf '%s' "$1" | tr -d '\000-\037\177;'; }

TITLE="$(sanitize "${MESSAGE}")"
BODY="$(sanitize "${PROJECT_NAME} (${AGENT_NAME})")"

source "$(dirname "${BASH_SOURCE[0]}")/lib/wezterm-tty.sh"

TTY_PATH="$(find_tty "$PPID")"

if [ -n "$TTY_PATH" ] && [ -w "$TTY_PATH" ]; then
  { printf '\e]777;notify;%s;%s\e\\' "$TITLE" "$BODY" > "$TTY_PATH"; } 2>/dev/null
fi

exit 0
