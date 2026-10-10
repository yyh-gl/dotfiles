{ lib, mode, ... }: {
  homebrew = {
    enable = true;
    onActivation = {
      # applyのたびにHomebrewを更新すると、同じflake.lockでも結果が変わりapplyも遅くなる。更新は`make brew-upgrade`で行う
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };
    taps = [
      "songmu/tap"
    ];
    brews = [
      "deck"
      "imagemagick"
      "mermaid-cli"
      "hunk"
      "python@3.11"
      "songmu/tap/laminate"
    ];
    casks = [
      "codex"
      "font-hackgen-nerd"
      "font-ricty-diminished"
      "1password"
      "docker-desktop"
      "figma"
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
      "visual-studio-code"
      "wezterm"
      "zoom"
    ] ++ lib.optionals (mode == "hobby") [
      "adobe-acrobat-reader"
      "discord"
      "godot"
      "tailscale-app"
    ];
    masApps = lib.optionalAttrs (mode == "hobby") {
      "1Password for Safari" = 1569813296;
      "Kindle"               = 302584613;
      "LINE"                 = 539883307;
      "Skitch"               = 425955336;
    };
  };
}
