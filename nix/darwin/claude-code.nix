{ lib, dotfiles, ... }:
let
  # 旧配置（managed-settings.json）にあった、dotfilesの過去版のsha256。一致したときだけ自動で消す
  # （drop-inとマージされ続け、消したルールが効き続けるのを防ぐ。手で編集された旧ファイルには触らない）
  legacyManagedSettingsHashes = [
    "2a530526e15061df0b03488eb6a6dfa9ec155f04520e58eb98cb55a9ceba7df1"
    "31f2989bbc246b508ed16ca9920dfb422eb794b4fb26b7bfa033efd1f544fd0e"
    "7996ed2338e075b0e94571785137240661c88d5e68021037902f9fcf65ec2bca"
    "7db367a165626a37f41cf0b31ef9c610bafd3dfa99c4ae1dda4fa4e5761d035e"
    "7f667cb2160c9f0abc1f7811c50058a289b17df374854ca5091b6af31fa8bbc2"
    "85ee59741f4226d51c48ee73ac9f88f86f1db6c18b8d11fc2e978b461d112fa5"
    "a4f7689efa0ed42b18474ea55441962d08a0bcff6c1dcd5f9b1893a4fa39cf77"
    "a64495faa592ed02534eb57355d7910b1444bbc5144030920f7c328db220a569"
    "ad313b33c90037124b2298646630cb33cdad04d3e227276f8e4c72dd23a7a35a"
    "b7c85e951067ca847b35d52e32063c7d651401c5c012f73d0ab8059c99e693b8"
    "bd5dbb208650876e6d9a8c56ebb1ff0de69edb50006c1c4c769278d3600e1e80"
    "d013e215221b668a513b5dbd6bc9bba281c249e5544a118e1084d9adba1d02ba"
  ];
in {
  # Claude Code自身は書き換えないmanaged settingsに置くことで、/model等の操作による自動再生成（claude-code#22659）から設定を保護する
  # managed-settings.json（先）とmanaged-settings.d/*.json（アルファベット順）は同じ層としてマージされて読まれる。
  # ほかのツールがmanaged-settings.jsonを使っても上書きし合わないよう、drop-inの50-dotfiles.jsonに置く
  # system.activationScripts.<任意の名前>.text はnix-darwinの実行リストに含まれず呼ばれないため、
  # 正式な差込口であるpostActivationに追記する
  # 仕事PCではMDMで/Library/Application Support/への書き込みが拒否されることがある。activationは失敗すると
  # 後続（codex.nixの配置を含む）まで止まるため、失敗しても警告だけ出して続ける
  system.activationScripts.postActivation.text = lib.mkAfter ''
    claude_dir="/Library/Application Support/ClaudeCode"
    claude_dropin="$claude_dir/managed-settings.d/50-dotfiles.json"
    legacy="$claude_dir/managed-settings.json"
    if [ -f "$legacy" ]; then
      legacy_hash="$(shasum -a 256 "$legacy" | cut -d' ' -f1)"
      case " ${lib.concatStringsSep " " legacyManagedSettingsHashes} " in
        *" $legacy_hash "*) rm -f "$legacy" || echo "warning: could not remove $legacy" >&2 ;;
        *) echo "warning: $legacy exists and is not a known dotfiles version; it is merged with the drop-in. Remove it by hand if unneeded" >&2 ;;
      esac
    fi
    if ! (
      set -e
      mkdir -p "$claude_dir/managed-settings.d"
      chmod 755 "$claude_dir/managed-settings.d"
      chown root:wheel "$claude_dir/managed-settings.d"
      install -m 644 -o root -g wheel "${dotfiles}/claude/managed-settings.json" "$claude_dropin"
    ); then
      echo "warning: could not install Claude Code managed settings to $claude_dropin (MDM may block it), skipping" >&2
    fi
  '';
}
