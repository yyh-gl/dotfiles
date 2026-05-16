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

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-vscode-extensions, ... }: {
    darwinConfigurations."yyh-gl-mac" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        { nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ]; }
        ./nix/darwin/default.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { dotfiles = self; };
          home-manager.users.yyh-gl = import ./nix/home/default.nix;
        }
      ];
    };
  };
}
