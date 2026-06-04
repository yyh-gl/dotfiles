{ lib, mode, ... }: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    taps = [
      "songmu/tap"
    ];
    brews = [
      "deck"
      "songmu/tap/laminate"
    ];
    casks = [
      "codex"
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
      "wezterm"
      "zoom"
    ] ++ lib.optionals (mode == "hobby") [
      "adobe-acrobat-reader"
      "discord"
      "1password"
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
