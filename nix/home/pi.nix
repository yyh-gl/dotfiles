{ dotfiles, lib, ... }:
let
  # pi/<kind>/直下のディレクトリをすべて~/.pi/agent/<kind>/<名前>へ個別にsymlinkする
  # pi/skills・pi/extensionsのどちらかがまだgitに追跡されていない（ディレクトリが存在しない）場合でも評価が落ちないようにする
  linkEntries = kind:
    let dir = "${dotfiles}/pi/${kind}";
    in lib.optionalAttrs (builtins.pathExists dir) (lib.mapAttrs' (name: _: lib.nameValuePair ".pi/agent/${kind}/${name}" { source = "${dir}/${name}"; })
      (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir)));
in {
  home.file = linkEntries "skills" // linkEntries "extensions";
}
