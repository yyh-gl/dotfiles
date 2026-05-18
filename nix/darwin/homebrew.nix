{ pkgs, lib, mode, ... }: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    taps = [
      "adoptopenjdk/openjdk"
      "hashicorp/tap"
      "mas-cli/tap"
      "sanemat/font"
      "songmu/tap"
      "supabase/tap"
      "weaveworks/tap"
    ];
    brews = [
      "awscli"
      "deck"
      "deno"
      "figlet"
      "pango"
      "fontforge"
      "fzf"
      "ghostscript"
      "gibo"
      "git"
      "gradle"
      "helm"
      "helmfile"
      "hub"
      "hugo"
      "jq"
      "kubernetes-cli"
      "kubectx"
      "libheif"
      "libraw"
      "libxmlsec1"
      "nghttp2"
      "nkf"
      "nmap"
      "node"
      "oath-toolkit"
      "okteto"
      "pnpm"
      "python@3.10"
      "silicon"
      "tcl-tk"
      "tig"
      "tree"
      "hashicorp/tap/terraform"
      "mas-cli/tap/mas"
      "songmu/tap/laminate"
      "starship"
      "weaveworks/tap/eksctl"
      "git-delta"
    ];
    casks = [
      "docker-desktop"
      "figma"
      "ghostty"
      "google-chrome"
      "google-drive"
      "google-japanese-ime"
      "jetbrains-toolbox"
      "karabiner-elements"
      "logi-options+"
      "notion"
      "obsidian"
      "postman"
      "rectangle"
      "slack"
      "switchhosts"
      "tableplus"
      "zoom"
    ] ++ lib.optionals (mode == "hobby") [
      "adobe-acrobat-reader"
      "discord"
      "1password"
      "1password-cli"
      "tailscale-app"
    ];
    masApps = lib.optionalAttrs (mode == "hobby") {
      "1Password for Safari" = 1569813296;
      "Kindle"               = 302584613;
      "LINE"                 = 539883307;
      "Skitch"               = 425955336;
      "Tailscale"            = 1475387142;
    };
  };
}
