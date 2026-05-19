{ mode, ... }: {
  programs.zsh = {
    enable = true;

    setOptions = [ "CORRECT" ];

    envExtra = ''
      if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "''${ZDOTDIR:-$HOME}/.zprofile" ]]; then
        source "''${ZDOTDIR:-$HOME}/.zprofile"
      fi
    '';

    profileExtra = ''
      if [[ "$OSTYPE" == darwin* ]]; then
        export BROWSER='open'
      fi

      export EDITOR='nano'
      export VISUAL='nano'
      export PAGER='less'

      if [[ -z "$LANG" ]]; then
        export LANG='jp_JP.UTF-8'
      fi

      typeset -gU cdpath fpath mailpath path
      path=(/usr/local/{bin,sbin} $path)

      export LESS='-F -g -i -M -R -S -w -X -z-4'

      if (( $#commands[(i)lesspipe(|.sh)] )); then
        export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
      fi

      if [[ ! -d "$TMPDIR" ]]; then
        export TMPDIR="/tmp/$LOGNAME"
        mkdir -p -m 700 "$TMPDIR"
      fi
      TMPPREFIX="''${TMPDIR%/}/zsh"

      eval $(/opt/homebrew/bin/brew shellenv)
    '';

    initContent = ''
      # Prompt
      eval "$(starship init zsh)"

      # PATH
      export LANG="$(defaults read -g AppleLocale | sed 's/@.*$//g').UTF-8"
      export EDITOR=emacs VISUAL=emacs

      export PATH=$PATH:$HOME/go/bin
      export PATH=$HOME/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/scripts:$PATH
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
      export PATH="/opt/homebrew/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      typeset -U path cdpath fpath manpath

      # Environment variables
      ${if mode == "hobby" then ''
      local _dotenv="$HOME/workspaces/github.com/yyh-gl/dotfiles/.env"
      if [[ -r "$_dotenv" ]]; then
        set -a
        source "$_dotenv"
        set +a
      fi
      '' else ""}

      # Completion
      zmodload zsh/complist
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # cd → ls
      cdls() { \cd "$@" && ls }

      # less color
      export LESS='-R'
      export LESSOPEN='| /usr/local/Cellar/source-highlight/3.1.8_5/bin/src-hilite-lesspipe.sh %s'

      # GCP gcloud
      if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
      if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

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

      # Bun completions
      [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
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
      cd       = "cdls";
      fix      = "e $HOME/.zshrc";
      load     = "exec $SHELL -l";
      ls       = "ls -GF";
      ll       = "ls -lGF";
      la       = "ls -alGF";
      e        = "emacs";
      fixe     = "e $HOME/.emacs.d/init.el";
      fixs     = "e $HOME/.ssh/config";
      xcode    = "open -a Xcode";
      k        = "kubectl";
      kc       = "kubectx";
      kn       = "kubens";
      dsh      = ''docker exec -it $(docker ps | fzf | cut -f 1 -d " ") /bin/bash'';
      ksh      = ''kubectl exec -it $(kubectl get po | fzf | cut -f 1 -d " ") -- /bin/bash'';
      mksh     = "make-shortcut.sh";
      mksl     = "make-symbolic-link.sh";
      dot      = "cd $HOME/workspaces/github.com/yyh-gl/dotfiles";
      my       = "cd $HOME/workspaces/github.com/yyh-gl/my-agent-teams";
    } // (if mode == "hobby" then {
      supabase = "npx supabase";
      sb       = "supabase";
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
      ts       = "tailscale";
      tf       = "terraform";
      play     = "cd $HOME/workspaces/github.com/yyh-gl/go-playground/";
      anti     = "cd $HOME/workspaces/github.com/Anti-Pattern-Inc/";
      blog     = "cd $HOME/workspaces/github.com/yyh-gl/tech-blog/";
      api      = "cd $HOME/workspaces/github.com/yyh-gl/hobigon-golang-api-server/";
      ur       = "cd $HOME/workspaces/github.com/yyh-gl/urLogs";
      hobigon  = "cd $HOME/workspaces/github.com/yyh-gl/hobigon/";
    } else if mode == "work" then {
      # Add aliases for work
    } else {});
  };
}
