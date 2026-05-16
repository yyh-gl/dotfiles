{ pkgs, ... }: {
  imports = [ ./homebrew.nix ];

  system.stateVersion = 6;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.yyh-gl = {
    name = "yyh-gl";
    home = "/Users/yyh-gl";
  };
}
