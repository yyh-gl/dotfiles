#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# レート制限の使用率に応じた色を返す
rate_color() {
  local val=$(printf "%.0f" "$1")
  if [ "$val" -ge 90 ]; then
    echo "\033[31m"  # 赤
  elif [ "$val" -ge 70 ]; then
    echo "\033[33m"  # 黄
  else
    echo "\033[32m"  # 緑
  fi
}

# プログレスバーを生成する（幅はデフォルト10）
make_bar() {
  local val=$(printf "%.0f" "$1")
  local width=${2:-10}
  local filled=$(( val * width / 100 ))
  local empty=$(( width - filled ))
  local bar=""
  for i in $(seq 1 $filled); do bar="${bar}█"; done
  for i in $(seq 1 $empty); do bar="${bar}░"; done
  echo "$bar"
}

# レート制限の表示文字列を組み立て
rate_info=""
if [ -n "$five_h" ]; then
  color=$(rate_color "$five_h")
  bar=$(make_bar "$five_h")
  rate_info="${color}5h:[${bar}]$(printf '%.0f' "$five_h")%%\033[0m"
fi
if [ -n "$seven_d" ]; then
  color=$(rate_color "$seven_d")
  bar=$(make_bar "$seven_d")
  rate_info="${rate_info:+$rate_info }${color}7d:[${bar}]$(printf '%.0f' "$seven_d")%%\033[0m"
fi

if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  bar=$(make_bar "$used")
  if [ -n "$rate_info" ]; then
    printf "\033[0;36m%s\033[0m  [%s] %d%% | $rate_info" "$model" "$bar" "$used_int"
  else
    printf "\033[0;36m%s\033[0m  [%s] %d%%" "$model" "$bar" "$used_int"
  fi
else
  if [ -n "$rate_info" ]; then
    printf "\033[0;36m%s\033[0m  [░░░░░░░░░░░░░░░░░░░░] -%% | $rate_info\n" "$model"
  else
    printf "\033[0;36m%s\033[0m  [░░░░░░░░░░░░░░░░░░░░] -%%\n" "$model"
  fi
fi
