# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#   The Smile Magic
#
# Editor:
#   Yusuke Honda <https://github.com/yyh-gl>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
	source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

##############################################
# PATH
##############################################

## IntelliJ上のターミナルで文字化けさせないための設定
export LANG="`defaults read -g AppleLocale | sed 's/@.*$//g'`.UTF-8"

## 既定エディタ
export EDITOR=emacs VISUAL=emacs

## Go
export GOPATH=$HOME/go/1.24.5
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

## scripts
export PATH=$HOME/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/scripts:$PATH

## JDK
# 使用したいJDKのバージョンを指定すること
export JAVA_HOME=$HOME/jvm/jdk-24.0.1.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

## Homebrew bin
export PATH="/opt/homebrew/bin:$PATH"

## 重複パスを削除
# TODO: パスはzshrcに書くべきではない？要調査
typeset -U path cdpath fpath manpath


##############################################
# Secret
##############################################

export OPENAI_API_KEY="$(cat $HOME/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/openai-api-key.txt)"


##############################################
# 「cd」後に「ls」を自動実行
##############################################

cdls ()
{
    \cd "$@" && ls
}
alias cd='cdls'


##############################################
# lessコマンドの色付け
##############################################

export LESS='-R'
export LESSOPEN='| /usr/local/Cellar/source-highlight/3.1.8_5/bin/src-hilite-lesspipe.sh %s'


##############################################
# GCP gcloud
##############################################

# 【注意】絶対パスで指定すること

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi


##############################################
# Git
##############################################

# ブランチ一覧表示からの git checkout 機能
gico() {
  local branches branch
  branches=$(git branch -vv)
  branch=$(echo "$branches" | fzf +m)
  # sed で現在選択中を意味する * を削除
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# 変更ファイル一覧表示からの git add 機能
giad() {
  # ローカル変数を定義（スコープ：関数内）
  local input key n addfiles
  while input=$(
      git status --short |
      # 2文字目から1文字抽出 = 変更があるファイルの抽出
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      # multi：Tab（Ctrl-i）にて複数選択できるようになる
      # exit-0：選択肢がないときに終了ようになる
      # expect：ctrl-d でファイル選択できるようにする
      fzf --multi --exit-0 --expect=ctrl-d); do
    # $input には選択したものが一行ずつ入っていく（最大2行） -> ctrl-d\nfile_name
    # <<< は変数の値をファイルとしてコマンドへ渡す
    key=$(head -1 <<< "$input") # コマンド部分を抽出
    # input の最終行（選択ファイル）を取得
    addfiles=(`echo $(tail "-1" <<< "$input")`)
    # [[]] は括弧内を評価するやつ
    # -z は文字列が空であることを確かめる
    # 空の場合は continue
    [[ -z "$addfiles" ]] && continue
    if [ "$key" = ctrl-d ]; then
      # ctrl-d ならば git diff
      git diff --color=always $addfiles | less -R
    else
      # Enter ならば git add
      git add $addfiles
    fi
  done
}

gla() {
    default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
    local dest_branch="${1:-$default_branch}"
    git switch $default_branch
    git fetch origin
    git reset --hard origin/$default_branch
    gh poi
    git switch $dest_branch
}


##############################################
#  anyenvセットアップ
##############################################
eval "$(anyenv init -)"


##############################################
# Gitのtmp保存/復元ショートカット
##############################################

rom() {
    git add .
    git cm -m "tmp"
}

back() {
    git reset --soft $(git rev-parse head~)
    git restore --staged .
}


##############################################
#  追加機能（シェルスクリプト）
##############################################

# ショートカット作成プログラム
alias mksh='make-shortcut.sh'
# シンボリックリンク作成プログラム
alias mksl='make-symbolic-link.sh'

##############################################
# エイリアス
##############################################

alias fix='e $HOME/workspaces/github.com/yyh-gl/dotfiles/.zshrc'
alias load='exec $SHELL -l'

## 開発関連
alias fixe='e $HOME/workspaces/github.com/yyh-gl/dotfiles/.emacs.d/init.el'
alias fixs='e $HOME/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.ssh/config'
alias xcode='open -a Xcode'
alias tf='terraform'
alias k='kubectl'
alias kc='kubectx'
alias kn='kubens'
alias tailscale='/Applications/Tailscale.app/Contents/MacOS/Tailscale'
alias ts='tailscale'
alias dsh='docker exec -it $(docker ps | fzf | cut -f 1 -d " ") /bin/bash'
alias ksh='kubectl exec -it $(kubectl get po | fzf | cut -f 1 -d " ") -- /bin/bash'
alias sb='supabase'

## Anti-Pattern用ショートカット
alias anti='cd $HOME/workspaces/github.com/Anti-Pattern-Inc/engineed-dev-env/'

## ショートカット
alias blog='cd $HOME/workspaces/github.com/yyh-gl/tech-blog/'
alias api='cd $HOME/workspaces/github.com/yyh-gl/hobigon-golang-api-server/'
alias play='cd $HOME/workspaces/github.com/yyh-gl/go-playground/'
alias hobigon='cd $HOME/workspaces/github.com/yyh-gl/hobigon/'
alias dot='$HOME/workspaces/github.com/yyh-gl/dotfiles'
