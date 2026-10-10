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
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    username = "yyh-gl";
    homeDirectory = "/Users/${username}";
    makeDarwinSystem = mode:
      assert nixpkgs.lib.elem mode [ "hobby" "work" ];
      nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { dotfiles = self; inherit mode username homeDirectory; };
        modules = [
          {
            nixpkgs.overlays = [
              # pandas-stubsのテストがpytest 9.1のPytestRemovedIn10Warningでエラーになりビルド失敗するため一時的にスキップ
              # (nixpkgs-unstable側のpytestバージョンアップとpandas-stubsのテストコードの非互換。upstream修正待ち)
              # 外す条件: nix flake update後にこのoverlayなしでpandas-stubsがビルドできるようになったら削除する（`nix build nixpkgs#python3Packages.pandas-stubs`で確認）
              (final: prev: {
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                  (pyfinal: pyprev: {
                    pandas-stubs = pyprev.pandas-stubs.overrideAttrs (_: {
                      doCheck = false;
                      doInstallCheck = false;
                      pythonImportsCheck = [ ];
                    });
                  })
                ];
              })
            ];
          }
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
