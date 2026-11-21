{ dotfiles, lib, ... }:
let
  # pi/<kind>/直下のディレクトリをすべて~/.pi/agent/<kind>/<名前>へ個別にsymlinkする
  # pi/skills・pi/extensionsのどちらかがまだgitに追跡されていない（ディレクトリが存在しない）場合でも評価が落ちないようにする
  linkEntries = kind:
    let dir = "${dotfiles}/pi/${kind}";
    in lib.optionalAttrs (builtins.pathExists dir) (lib.mapAttrs' (name: _: lib.nameValuePair ".pi/agent/${kind}/${name}" { source = "${dir}/${name}"; })
      (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir)));
  # キーバインド設定（単一ファイル）。Piは未知キーの移行時だけ書き込むが、
  # 移行対象（旧キー名）が無ければ書き込まれないため、symlinkでも安全
  keybindingsFile = "${dotfiles}/pi/keybindings.json";
in {
  home.file = linkEntries "skills" // linkEntries "extensions"
    // lib.optionalAttrs (builtins.pathExists keybindingsFile) {
      ".pi/agent/keybindings.json".source = keybindingsFile;
    };
}
