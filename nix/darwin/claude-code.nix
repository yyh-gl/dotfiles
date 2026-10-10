{ lib, dotfiles, ... }: {
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
