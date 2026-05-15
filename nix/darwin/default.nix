{ pkgs, ... }: {
  system.stateVersion = 6;

  services.nix-daemon.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.yyh-gl = {
    name = "yyh-gl";
    home = "/Users/yyh-gl";
  };
}
