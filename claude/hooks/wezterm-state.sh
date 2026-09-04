#!/bin/bash
# Claude CodeのhookイベントからWezTermタブの状態表示を更新する。
# OSC 1337 SetUserVarでペインのuser var "claude_state" を書き換え、
# wezterm.luaのformat-tab-titleがそれを読んでアイコン・背景色を切り替える。
#
# usage: bash wezterm-state.sh <waiting|done|none> [--force]
#
# 注意:
#   - stdoutには何も書かない（PermissionRequest/UserPromptSubmit/SessionStartは
#     stdoutをJSON判定やコンテキスト追加として解釈するため）
#   - 常にexit 0。tty書き込み失敗・jq不在などでClaude Code本体を止めない

exec >/dev/null

STATE="${1:-}"
FORCE=0
if [ "${2:-}" = "--force" ]; then
  FORCE=1
fi

case "$STATE" in
  waiting|done|none) ;;
  *) exit 0 ;;
esac

# stdin JSON読み取り（対話端末からの手動実行では空JSON扱いにしてブロックを避ける）
if [ -t 0 ]; then
  INPUT='{}'
else
  INPUT="$(cat 2>/dev/null)"
  [ -z "$INPUT" ] && INPUT='{}'
fi

AGENT_ID=""
if command -v jq >/dev/null 2>&1; then
  AGENT_ID="$(printf '%s' "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null)"
fi

# 並列subagentのツール完了がmain agentの待ち表示を消してしまうのを防ぐ
if [ "$STATE" = "none" ] && [ -n "$AGENT_ID" ] && [ "$FORCE" -ne 1 ]; then
  exit 0
fi

source "$(dirname "${BASH_SOURCE[0]}")/lib/wezterm-tty.sh"

TTY_PATH="$(find_tty "$PPID")"
[ -z "$TTY_PATH" ] && exit 0
[ -w "$TTY_PATH" ] || exit 0

STATE_DIR="${TMPDIR:-/tmp}/claude-wezterm-state"
mkdir -p "$STATE_DIR" 2>/dev/null
STATE_FILE="${STATE_DIR}/$(basename "$TTY_PATH")"

if [ "$FORCE" -ne 1 ] && [ -r "$STATE_FILE" ]; then
  PREV="$(cat "$STATE_FILE" 2>/dev/null)"
  if [ "$PREV" = "$STATE" ]; then
    exit 0
  fi
fi

ENCODED="$(printf '%s' "$STATE" | base64 | tr -d '\n')"
{ printf '\e]1337;SetUserVar=claude_state=%s\a' "$ENCODED" > "$TTY_PATH"; } 2>/dev/null

printf '%s' "$STATE" > "$STATE_FILE" 2>/dev/null

exit 0
