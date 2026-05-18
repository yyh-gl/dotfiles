{ dotfiles, lib, config, mode, ... }: {
  home.file.".config/ghostty/config".source = "${dotfiles}/ghostty-config";
  home.file.".config/starship.toml".source = "${dotfiles}/starship.toml";
  home.file.".config/git/config".source = "${dotfiles}/.git-config/config";
  home.file.".config/git/ignore".source = "${dotfiles}/.git-config/ignore";

  home.activation.karabiner = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dotfiles="${config.home.homeDirectory}/workspaces/github.com/yyh-gl/dotfiles"
    mkdir -p "${config.home.homeDirectory}/.config/karabiner"
    ln -sf "$dotfiles/karabiner.json" \
      "${config.home.homeDirectory}/.config/karabiner/karabiner.json"
  '';

  home.activation.desktopSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.optionalString (mode == "hobby") ''
      mkdir -p "${config.home.homeDirectory}/Desktop/hobby"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/00_Engineering" \
        "${config.home.homeDirectory}/Desktop/hobby"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/01_CasualLife" \
        "${config.home.homeDirectory}/Desktop/hobby"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/00_Profile" \
        "${config.home.homeDirectory}/Pictures/00_Profile"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/01_Wallpapers" \
        "${config.home.homeDirectory}/Pictures/01_Wallpapers"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/02_Geeks" \
        "${config.home.homeDirectory}/Pictures/02_Geeks"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/03_IconsForMac" \
        "${config.home.homeDirectory}/Pictures/03_IconsForMac"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/04_SlackStamps" \
        "${config.home.homeDirectory}/Pictures/04_SlackStamps"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/05_Works" \
        "${config.home.homeDirectory}/Pictures/05_Works"
      ln -sf "${config.home.homeDirectory}/Google Drive/マイドライブ/01_Personal/01_CasualLife/99_Pictures/99_Others" \
        "${config.home.homeDirectory}/Pictures/99_Others"
    ''}
    ${lib.optionalString (mode == "work") ''
      mkdir -p "${config.home.homeDirectory}/Desktop/work"
    ''}
  '';
}
