{ pkgs, username, homeDirectory, ... }: {
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.delta
    pkgs.fzf
    pkgs.gopls
    pkgs.jq
    pkgs.nkf
    pkgs.nmap
    pkgs.starship
    pkgs.tree
  ];

  programs.go = {
    enable = true;
    package = pkgs.go_1_26;
    env.GOPATH = "$HOME/go";
    env.GOBIN  = "$HOME/go/bin";
  };

  programs.java = {
    enable = true;
    package = pkgs.jdk25;
  };

  imports = [
    ./dotfiles.nix
    ./zsh.nix
    ./vscode.nix
    ./emacs.nix
    ./claude.nix
    ./gh.nix
  ];
}
