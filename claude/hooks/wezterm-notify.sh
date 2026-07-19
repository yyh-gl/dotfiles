#!/bin/bash

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

MESSAGE="${1}"
AGENT_NAME="${2:-main}"

TITLE="${MESSAGE}"
BODY="${PROJECT_NAME} (${AGENT_NAME})"

# hookはClaude Code本体のサブプロセスとして起動されておりcontrolling ttyを持たないため、
# /dev/ttyへの書き込みはENXIO(Device not configured)で失敗する。
# 親プロセスを遡って実際にttyを持つプロセスを探し、そのttyデバイスファイルへ直接書き込む。
find_tty() {
  local pid="$1"
  while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
    local tty
    tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$tty" ] && [ "$tty" != "??" ]; then
      printf '/dev/%s' "$tty"
      return 0
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
  return 1
}

TTY_PATH="$(find_tty "$PPID")"

if [ -n "$TTY_PATH" ] && [ -w "$TTY_PATH" ]; then
  { printf '\e]777;notify;%s;%s\e\\' "$TITLE" "$BODY" > "$TTY_PATH"; } 2>/dev/null
fi

exit 0
