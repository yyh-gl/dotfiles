#!/bin/zsh -f
# .zloginからsourceされるため、zshプロセスもサブシェルもforkしない。zsh/datetimeだけで日数を計算する。
# 直接実行しても動く。CELEBRATE_TODAY=YYYY-MM-DDで「今日」を差し替えられる（テスト用）。

zmodload zsh/datetime

# YYYY-MM-DDをその日の正午のepoch秒にしてREPLYに入れる（夏時間などで日数がずれないよう正午を使う）
_celebrate_day_epoch() {
  strftime -s REPLY -r '%Y-%m-%d %H:%M:%S' "$1 12:00:00"
}

celebrate_anniversary() {
  # 記念日（2024-11-10）
  local -i year=2024 month=11 day=10
  # 半年記念日の月（6か月後）。日は同じ
  local -i half_month=$(( (month + 5) % 12 + 1 ))

  local today date_str
  if [[ -n "$CELEBRATE_TODAY" ]]; then
    today="$CELEBRATE_TODAY"
  else
    strftime -s today '%Y-%m-%d' $EPOCHSECONDS
  fi
  local -i current_year=${today%%-*} today_sec anniversary_sec next_half_sec next_year_sec

  _celebrate_day_epoch $today;                 today_sec=$REPLY
  printf -v date_str '%04d-%02d-%02d' $year $month $day
  _celebrate_day_epoch $date_str;              anniversary_sec=$REPLY

  # 今年の記念日が過去なら来年にして、epoch秒をREPLYに入れる
  local -i target_month
  for target_month in $half_month $month; do
    printf -v date_str '%04d-%02d-%02d' $current_year $target_month $day
    _celebrate_day_epoch $date_str
    if (( REPLY < today_sec )); then
      printf -v date_str '%04d-%02d-%02d' $(( current_year + 1 )) $target_month $day
      _celebrate_day_epoch $date_str
    fi
    if (( target_month == half_month )); then next_half_sec=$REPLY; else next_year_sec=$REPLY; fi
  done

  print
  print "<< Important Day >>"
  print "Passed Days -> $(( (today_sec - anniversary_sec) / 86400 )) days passed"
  print "Next Half Important Day -> $(( (next_half_sec - today_sec) / 86400 )) days left"
  print "Next Year Important Day -> $(( (next_year_sec - today_sec) / 86400 )) days left"
}

celebrate_anniversary
