#!/bin/bash
# WezTermの通知・状態hookが共有するttyヘルパー。
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
