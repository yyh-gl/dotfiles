{ pkgs, ... }: {
  home.username = "yyh-gl";
  home.homeDirectory = "/Users/yyh-gl";
  home.stateVersion = "26.05";

  # フェーズ1: programs.zsh でzsh設定を追加
  # フェーズ2: home.file でghostty/starship/git設定を追加
}
