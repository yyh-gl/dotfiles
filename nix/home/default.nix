{ pkgs, ... }: {
  home.username = "yyh-gl";
  home.homeDirectory = "/Users/yyh-gl";
  home.stateVersion = "26.05";

  home.packages = [ pkgs.gopls ];

  imports = [
    ./dotfiles.nix
    ./zsh.nix
    ./vscode.nix
  ];
}
