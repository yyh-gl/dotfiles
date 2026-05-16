{ pkgs, ... }: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
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
      "gh"
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
      "adobe-acrobat-reader"
      "discord"
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
    ];
  };
}
