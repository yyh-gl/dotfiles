{
  description = "yyh-gl's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-vscode-extensions, ... }:
  let
    username = "yyh-gl";
    homeDirectory = "/Users/${username}";
    makeDarwinSystem = mode:
      assert nixpkgs.lib.elem mode [ "hobby" "work" ];
      nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit mode username homeDirectory; };
        modules = [
          { nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ]; }
          ./nix/darwin/default.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { dotfiles = self; inherit mode username homeDirectory; };
            home-manager.users.${username} = import ./nix/home/default.nix;
          }
        ];
      };
  in {
    darwinConfigurations = {
      "yyh-gl-mac-hobby" = makeDarwinSystem "hobby";
      "yyh-gl-mac-work"  = makeDarwinSystem "work";
    };
  };
}
