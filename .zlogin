#
# Executes commands at login post-zshrc.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Execute code that does not affect the current session in the background.
{
  # Compile the completion dump to increase startup speed.
  zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
  if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
    zcompile "$zcompdump"
  fi
} &!

# Print a random, hopefully interesting, adage.
if (( $+commands[fortune] )); then
  if [[ -t 0 || -t 1 ]]; then
    fortune -s
    print
  fi
fi

## IPアドレスを表示
echo "\n<< Used IP address >>"
echo -n " -> "
ipconfig getifaddr en0 || echo "No Connection"

## ディスク使用度
echo "\n<< Machine Used >>"
df -h .

## 起動時間
echo "\n<< Uptime >>"
echo -n " -> "
uptime

## 記念日カウント
./celebrate-anniversary.sh

## ログイン時メッセージ
echo
# figlet -f cosmic welcome
figlet -f banner3-D -w 300 Welcome
