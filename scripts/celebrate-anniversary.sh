#!/bin/zsh -f
# .zloginから毎回呼ばれるため、外部コマンドをforkしないようzsh/datetimeだけで日数を計算する。
# CELEBRATE_TODAY=YYYY-MM-DDで「今日」を差し替えられる（テスト用）。

zmodload zsh/datetime

# 記念日（2024-11-10）
typeset -i ANNIVERSARY_YEAR=2024 ANNIVERSARY_MONTH=11 ANNIVERSARY_DAY=10
# 半年記念日の月（6か月後）。日は同じ
typeset -i HALF_MONTH=$(( (ANNIVERSARY_MONTH + 5) % 12 + 1 ))

# YYYY-MM-DDをその日の正午のepoch秒にする（夏時間などで日数がずれないよう正午を使う）
day_epoch() {
  strftime -s REPLY -r '%Y-%m-%d %H:%M:%S' "$1 12:00:00"
}

if [[ -n "$CELEBRATE_TODAY" ]]; then
  today="$CELEBRATE_TODAY"
else
  strftime -s today '%Y-%m-%d' $EPOCHSECONDS
fi
typeset -i current_year=${today%%-*}

day_epoch $today;                                               typeset -i today_sec=$REPLY
day_epoch "$ANNIVERSARY_YEAR-$ANNIVERSARY_MONTH-$ANNIVERSARY_DAY"; typeset -i anniversary_sec=$REPLY

# 今年の記念日が過去なら来年にする
next_epoch() {
  local month=$1 day=$2
  day_epoch "$(printf '%04d-%02d-%02d' $current_year $month $day)"
  if (( REPLY < today_sec )); then
    day_epoch "$(printf '%04d-%02d-%02d' $(( current_year + 1 )) $month $day)"
  fi
}

next_epoch $HALF_MONTH $ANNIVERSARY_DAY;        typeset -i next_half_sec=$REPLY
next_epoch $ANNIVERSARY_MONTH $ANNIVERSARY_DAY; typeset -i next_year_sec=$REPLY

print
print "<< Important Day >>"
print "Passed Days -> $(( (today_sec - anniversary_sec) / 86400 )) days passed"
print "Next Half Important Day -> $(( (next_half_sec - today_sec) / 86400 )) days left"
print "Next Year Important Day -> $(( (next_year_sec - today_sec) / 86400 )) days left"
