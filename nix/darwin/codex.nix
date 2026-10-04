{ lib, ... }: {
  # Codexは/model・プロジェクトのtrust等で~/.codex/config.tomlを書き換え、「常に許可」で~/.codex/rules/default.rulesへ追記するため、
  # Codex自身が書き込まないsystem層（/etc/codex）に置く。
  # symlinkは読み込まれないことがあるため、environment.etc（/etc/static経由のsymlink）ではなく実ファイルとしてコピーする
  # requirements.tomlはユーザーが上書きできない強制設定、managed_config.tomlはuser層より優先される既定値
  system.activationScripts.postActivation.text = lib.mkAfter ''
    mkdir -p /etc/codex
    # 旧構成のconfig.tomlとdotfiles.rulesは二重になるため消す。Nix管理外の他のrulesは残す
    rm -f /etc/codex/config.toml /etc/codex/rules/dotfiles.rules
    install -m 644 -o root -g wheel "${toString ./../../codex/requirements.toml}" /etc/codex/requirements.toml
    install -m 644 -o root -g wheel "${toString ./../../codex/managed_config.toml}" /etc/codex/managed_config.toml
  '';
}
