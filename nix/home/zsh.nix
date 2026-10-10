{ mode, lib, pkgs, config, ... }:
let
  # starship init zshの出力をビルド時に生成する（起動のたびに実行するとfork分だけ遅くなる）。
  # 次の2点だけ置き換える。
  # - RPROMPT: right_formatを使っていないのに、毎プロンプトstarshipが起動されるのを避ける
  # - PROMPT2: `starship prompt --continuation`の出力（デフォルト値）を静的にする
  starshipInit = pkgs.runCommand "starship-init.zsh" { nativeBuildInputs = [ pkgs.starship ]; } ''
    export HOME=$TMPDIR
    starship init zsh --print-full-init | grep -v -e '^RPROMPT=' -e '^PROMPT2=' > $out
    cat >> $out <<'EOF'
    RPROMPT=""
    PROMPT2=$'%{\e[90m%}∙%{\e[0m%} '
    EOF
  '';
in {
  programs.zsh = {
    enable = true;

    setOptions = [ "CORRECT" ];

    # compinitはここで1回だけ実行する（nix-darwin側は無効化済み）。
    # -Cはcompauditと.zcompdumpの鮮度チェックを省略するため、下のactivationでapplyのたびにdumpを削除している。
    completionInit = "autoload -U compinit && compinit -C";

    envExtra = ''
      if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "''${ZDOTDIR:-$HOME}/.zprofile" ]]; then
        source "''${ZDOTDIR:-$HOME}/.zprofile"
      fi
    '';

    profileExtra = ''
      if [[ "$OSTYPE" == darwin* ]]; then
        export BROWSER='open'
      fi

      export PAGER='less'

      typeset -gU cdpath fpath mailpath path

      export LESS='-F -g -i -M -R -S -w -X -z-4'

      if (( $#commands[(i)lesspipe(|.sh)] )); then
        export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
      fi

      if [[ ! -d "$TMPDIR" ]]; then
        export TMPDIR="/tmp/$LOGNAME"
        mkdir -p -m 700 "$TMPDIR"
      fi
      TMPPREFIX="''${TMPDIR%/}/zsh"

      # `brew shellenv`の出力を静的に書いたもの（evalするとbrewの起動分だけ遅くなる）。
      # fpathの追加とexport FPATHは必須。.zprofileより後のcompinitが補完を拾うのと、
      # .zprofileを読まないネストしたシェルにFPATH経由で引き継ぐため。
      export HOMEBREW_PREFIX="/opt/homebrew"
      export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
      export HOMEBREW_REPOSITORY="/opt/homebrew"
      fpath[1,0]="/opt/homebrew/share/zsh/site-functions"
      export FPATH
      # Nixで入れたツール（git・nodeなど）を優先するため、Homebrewは後ろに足す（`brew shellenv`は先頭に足す）
      export PATH="''${PATH+$PATH:}/opt/homebrew/bin:/opt/homebrew/sbin"
      [ -z "''${MANPATH-}" ] || { export MANPATH="''${MANPATH%"''${MANPATH##*[!:]}"}"; export MANPATH=":''${MANPATH#"''${MANPATH%%[!:]*}"}"; }
      export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"
    '';

    initContent = ''
      # Prompt
      source ${starshipInit}

      # PATH
      export LANG=ja_JP.UTF-8
      export EDITOR=emacs VISUAL=emacs

      export PATH=$PATH:$HOME/go/bin
      export PATH="$HOME/.local/bin:$PATH"
      typeset -U path cdpath fpath manpath

      # Environment variables
      ${if mode == "hobby" then ''
      # sandbox内から書き換えられても任意コードが動かないよう、sourceせずKEY=VALUEの行だけを読む
      local _dotenv="$HOME/workspaces/github.com/yyh-gl/dotfiles/.env" _k _v
      if [[ -r "$_dotenv" ]]; then
        while IFS='=' read -r _k _v || [[ -n "$_k" ]]; do
          _k=''${_k#export }
          [[ "$_k" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] || continue
          _v=''${_v#\"}; _v=''${_v%\"}; _v=''${_v#\'}; _v=''${_v%\'}
          export "$_k=$_v"
        done < "$_dotenv"
      fi
      '' else ""}

      # Completion
      zmodload zsh/complist
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # cd → ls
      cdls() { \cd "$@" && ls -GF }

      # Git
      gico() {
        local branches branch
        branches=$(git branch -vv)
        branch=$(echo "$branches" | fzf +m)
        git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
      }

      giad() {
        local input key addfiles
        while input=$(
            git status --short |
            awk '{if (substr($0,2,1) !~ / /) print $2}' |
            fzf --multi --exit-0 --expect=ctrl-d); do
          key=$(head -1 <<< "$input")
          addfiles=(`echo $(tail "-1" <<< "$input")`)
          [[ -z "$addfiles" ]] && continue
          if [ "$key" = ctrl-d ]; then
            git diff --color=always $addfiles | less -R
          else
            git add $addfiles
          fi
        done
      }

      gla() {
        default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
        local dest_branch="''${1:-$default_branch}"
        git switch $default_branch
        git fetch origin
        git reset --hard origin/$default_branch
        gh poi
        git switch $dest_branch
      }

      rom() {
        git add .
        git cm -m "tmp"
      }

      back() {
        git reset --soft $(git rev-parse head~)
        git restore --staged .
      }

    '';

    loginExtra = ''
      {
        zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump"
        if [[ -s "$zcompdump" && (! -s "''${zcompdump}.zwc" || "$zcompdump" -nt "''${zcompdump}.zwc") ]]; then
          zcompile "$zcompdump"
        fi
      } &!

      if (( $+commands[fortune] )); then
        if [[ -t 0 || -t 1 ]]; then
          fortune -s
          print
        fi
      fi

      echo "\n<< Used IP address >>"
      echo -n " -> "
      ipconfig getifaddr en0 || echo "No Connection"

      echo "\n<< Machine Used >>"
      df -h .

      echo "\n<< Uptime >>"
      echo -n " -> "
      uptime

      celebrate-anniversary.sh

      echo
      figlet -f banner3-D -w 300 Welcome
    '';

    logoutExtra = ''
      cat <<-'EOF'

      Thank you. Come again!
        -- Dr. Apu Nahasapeemapetilon
      EOF
    '';

    shellAliases = {
      cd = "cdls";
      fix = "e $HOME/.zshrc";
      load = "exec $SHELL -l";
      ls = "ls -GF";
      ll = "ls -lGF";
      la = "ls -alGF";
      e = "emacs";
      fixe = "e $HOME/.emacs.d/init.el";
      fixs = "e $HOME/.ssh/config";
      xcode = "open -a Xcode";
      k = "kubectl";
      kc = "kubectx";
      kn = "kubens";
      dsh = ''docker exec -it $(docker ps | fzf | cut -f 1 -d " ") /bin/bash'';
      ksh = ''kubectl exec -it $(kubectl get po | fzf | cut -f 1 -d " ") -- /bin/bash'';
      dot = "cd $HOME/workspaces/github.com/yyh-gl/dotfiles";
      my = "cd $HOME/workspaces/github.com/yyh-gl/my-agent-teams";
    } // (if mode == "hobby" then {
      supabase = "npx supabase";
      sb = "supabase";
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
      ts = "tailscale";
      tf = "terraform";
      play = "cd $HOME/workspaces/github.com/yyh-gl/go-playground/";
      anti = "cd $HOME/workspaces/github.com/Anti-Pattern-Inc/";
      blog = "cd $HOME/workspaces/github.com/yyh-gl/tech-blog/";
      api = "cd $HOME/workspaces/github.com/yyh-gl/hobigon-golang-api-server/";
      ur = "cd $HOME/workspaces/github.com/yyh-gl/urLogs";
      hobigon = "cd $HOME/workspaces/github.com/yyh-gl/hobigon/";
      br = ''cd "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/main"'';
      sl = "cd $HOME/workspaces/github.com/yyh-gl/slide-decks/";
      kf = "cd $HOME/workspaces/github.com/yyh-gl/slide-decks/slides/261114_kotlin-fest_lincheck/";
      ant = "cd $HOME/workspaces/github.com/yyh-gl/assist-ant/";
    } else if mode == "work" then {
      # Add aliases for work
    } else {});
  };

  # compinit -Cは補完の追加を自動検知しないので、applyのたびに.zcompdumpを捨てて次の起動で作り直させる
  home.activation.resetZcompdump = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -f "${config.home.homeDirectory}/.zcompdump" "${config.home.homeDirectory}/.zcompdump.zwc"
  '';
}
