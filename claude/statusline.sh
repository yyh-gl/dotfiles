#!/usr/bin/env bash
input=$(cat)

# 必要なフィールドを1回のjq呼び出しでまとめて抽出（1行1フィールド）
mapfile -t fields < <(echo "$input" | jq -r '
  (.workspace.current_dir // ""),
  (.model.display_name // "Claude"),
  (.context_window.used_percentage // ""),
  (.rate_limits.five_hour.used_percentage // ""),
  (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.used_percentage // ""),
  (.rate_limits.seven_day.resets_at // ""),
  (.cost.total_cost_usd // "")
')
current_dir="${fields[0]}"
model="${fields[1]}"
ctx_used="${fields[2]}"
five_h="${fields[3]}"
five_reset="${fields[4]}"
seven_d="${fields[5]}"
seven_reset="${fields[6]}"
cost_usd="${fields[7]}"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
DIM="\033[2m"
RESET="\033[0m"

# 使用率に応じた色を返す（<70%緑 / 70-89%黄 / >=90%赤）
rate_color() {
  local val
  val=$(printf "%.0f" "$1")
  if [ "$val" -ge 90 ]; then
    echo "$RED"
  elif [ "$val" -ge 70 ]; then
    echo "$YELLOW"
  else
    echo "$GREEN"
  fi
}

# epoch秒 -> HH:MM（macOSのBSD date優先、Linuxのdate -dにフォールバック）
fmt_time() {
  local epoch
  epoch=$(printf "%.0f" "$1")
  date -r "$epoch" +%H:%M 2>/dev/null || date -d "@$epoch" +%H:%M 2>/dev/null
}

# epoch秒 -> M/D HH:MM（先頭ゼロなし）
fmt_date_time() {
  local epoch out m d t
  epoch=$(printf "%.0f" "$1")
  out=$(date -r "$epoch" '+%m %d %H:%M' 2>/dev/null) \
    || out=$(date -d "@$epoch" '+%m %d %H:%M' 2>/dev/null) \
    || return
  read -r m d t <<<"$out"
  printf '%d/%d %s' "$((10#$m))" "$((10#$d))" "$t"
}

# 空文字列を除いてセグメントを「 | 」（dim）で連結
join_segments() {
  local sep=" ${DIM}|${RESET} " out="" s
  for s in "$@"; do
    [ -z "$s" ] && continue
    out="${out:+${out}${sep}}${s}"
  done
  printf '%s' "$out"
}

# ---- 1行目: ディレクトリ + gitブランチ ----
dir_seg=""
branch_seg=""
if [ -n "$current_dir" ]; then
  dir_seg="📁${CYAN}$(basename "$current_dir")${RESET}"
  branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
  [ -n "$branch" ] && branch_seg="${YELLOW}⎇ ${branch}${RESET}"
fi

# ---- 2行目: モデル + コンテキスト使用率 + レート制限 ----
model_seg="🤖${CYAN}${model}${RESET}"

ctx_seg=""
if [ -n "$ctx_used" ]; then
  ctx_seg="📈$(rate_color "$ctx_used")$(printf '%.0f' "$ctx_used")%${RESET}"
fi

five_seg=""
if [ -n "$five_h" ]; then
  five_seg="🕐5h $(rate_color "$five_h")$(printf '%.0f' "$five_h")%${RESET}"
  if [ -n "$five_reset" ]; then
    five_seg="${five_seg} ${DIM}↺$(fmt_time "$five_reset")${RESET}"
  fi
fi

seven_seg=""
if [ -n "$seven_d" ]; then
  seven_seg="📅7d $(rate_color "$seven_d")$(printf '%.0f' "$seven_d")%${RESET}"
  if [ -n "$seven_reset" ]; then
    seven_seg="${seven_seg} ${DIM}↺$(fmt_date_time "$seven_reset")${RESET}"
  fi
fi

# ---- 3行目: セッションコスト ----
cost_seg=""
if [ -n "$cost_usd" ]; then
  cost_seg="💰\$$(printf '%.2f' "$cost_usd") ${DIM}(session)${RESET}"
fi

line1=$(join_segments "$dir_seg" "$branch_seg")
line2=$(join_segments "$model_seg" "$ctx_seg" "$five_seg" "$seven_seg")
line3="$cost_seg"

out=""
for line in "$line1" "$line2" "$line3"; do
  [ -z "$line" ] && continue
  out="${out:+${out}\n}${line}"
done
printf '%b\n' "$out"
