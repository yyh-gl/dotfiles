{ dotfiles, lib, config, mode, ... }:
let
  hd = config.home.homeDirectory;
  gd = "${hd}/Google Drive/マイドライブ/01_Personal";
  hobbySymlinks = [
    { src = "${gd}/00_Engineering";                          dst = "${hd}/Desktop/hobby/00_Engineering"; }
    { src = "${gd}/01_CasualLife";                           dst = "${hd}/Desktop/hobby/01_CasualLife"; }
    { src = "${gd}/01_CasualLife/99_Pictures/00_Profile";    dst = "${hd}/Pictures/00_Profile"; }
    { src = "${gd}/01_CasualLife/99_Pictures/01_Wallpapers"; dst = "${hd}/Pictures/01_Wallpapers"; }
    { src = "${gd}/01_CasualLife/99_Pictures/02_Geeks";      dst = "${hd}/Pictures/02_Geeks"; }
    { src = "${gd}/01_CasualLife/99_Pictures/03_IconsForMac"; dst = "${hd}/Pictures/03_IconsForMac"; }
    { src = "${gd}/01_CasualLife/99_Pictures/04_SlackStamps"; dst = "${hd}/Pictures/04_SlackStamps"; }
    { src = "${gd}/01_CasualLife/99_Pictures/05_Works";      dst = "${hd}/Pictures/05_Works"; }
    { src = "${gd}/01_CasualLife/99_Pictures/99_Others";     dst = "${hd}/Pictures/99_Others"; }
  ];
in {
  home.file.".config/ghostty/config".source = "${dotfiles}/ghostty-config";
  home.file.".config/starship.toml".source = "${dotfiles}/starship.toml";
  home.file.".config/git/config".source = "${dotfiles}/.git-config/config";
  home.file.".config/git/ignore".source = "${dotfiles}/.git-config/ignore";
  home.file.".config/karabiner/karabiner.json".source = "${dotfiles}/karabiner.json";

  home.activation.desktopSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.optionalString (mode == "hobby") (''
      mkdir -p "${hd}/Desktop/hobby"
    '' + lib.concatMapStrings (sl: ''
      ln -sf "${sl.src}" "${sl.dst}"
    '') hobbySymlinks)}
    ${lib.optionalString (mode == "work") ''
      mkdir -p "${hd}/Desktop/work"
    ''}
  '';
}
