{ lib, config, dotfiles, pkgs, ... }:
let
  hd = config.home.homeDirectory;
  op = "${pkgs._1password-cli}/bin/op";
  # 1Passwordがロック中・CLI連携が無効などでopが失敗すると、home-managerのactivationがそこで止まって
  # 後続のClaude設定やmodの配置まで適用されない。失敗は警告だけ出して続ける
  injects = [
    { tpl = "ssh-config.tpl";      out = ".ssh/config"; }
    { tpl = "aws-credentials.tpl"; out = ".aws/credentials"; }
    { tpl = "kube-config.tpl";     out = ".kube/config"; }
    { tpl = "deck-credentials.tpl"; out = ".local/share/deck/credentials.json"; }
  ];
  opHelpers = ''
    op_read() { # <op:// reference> <output file>
      if ${op} read "$1" --out-file "$2" --force; then
        chmod 600 "$2"
      else
        echo "warning: op read failed for $1, skipping $2" >&2
      fi
    }
    op_inject() { # <template> <output file>
      if ${op} inject -i "$1" -o "$2" --force; then
        chmod 600 "$2"
      else
        echo "warning: op inject failed for $1, skipping $2" >&2
      fi
    }
  '';
in {
  home.packages = [ pkgs._1password-cli ];

  # 公開鍵は秘密ではないので、symlinkで配置する
  home.file = lib.genAttrs
    (map (name: ".ssh/keys/${name}.pub") [ "hobigon-k8s-master" "hobigon-k8s-worker" "hobigon-wsl" ])
    (path: { source = "${dotfiles}/${path}"; });

  home.activation.sshSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${hd}/.ssh/keys"
    chmod 700 "${hd}/.ssh"
    chmod 700 "${hd}/.ssh/keys"
  '';

  # Import SSH private keys from 1Password so they can be referenced locally
  # (e.g. as an IdentityFile / git commit signingkey) without hitting 1Password
  # on every use. 1Password items needed (vault: PC):
  #   - "GitHub" : SSH Key (GitHub authentication only; commit signing uses "GitHub Signing" below)
  #                private key field id is "private_key" (label is Japanese: "秘密鍵")
  home.activation.sshKeysImport = lib.hm.dag.entryAfter [ "writeBoundary" "sshSetup" ] ''
    ${opHelpers}
    op_read "op://PC/GitHub/private_key?ssh-format=openssh" "${hd}/.ssh/keys/github_yyh-gl"
  '';

  # Import the commit-signing-only SSH private key from 1Password. It lives outside
  # ~/.ssh so that the Claude Code sandbox (which denies ~/.ssh/keys) can read it for
  # `git commit`. The key is registered on GitHub as a *Signing Key* only, so a leak
  # cannot be used to authenticate or push. 1Password is the source of truth; the
  # local file is a derived copy overwritten on every apply.
  # 1Password items needed (vault: PC):
  #   - "GitHub Signing" : SSH Key (commit signing only)
  #                        private key field id is "private_key"
  home.activation.gitSigningKeyImport = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${opHelpers}
    mkdir -p "${hd}/.config/git"
    op_read "op://PC/GitHub Signing/private_key?ssh-format=openssh" "${hd}/.config/git/github_signing_ed25519"
    # git log --show-signatureで署名を検証するための許可リスト（公開鍵なので秘密ではない）
    if public_key="$(${op} read "op://PC/GitHub Signing/public_key")"; then
      printf '%s %s\n' "yhonda.95.gl@gmail.com" "$public_key" > "${hd}/.config/git/allowed_signers"
    else
      echo "warning: op read failed for the signing public key, skipping allowed_signers" >&2
    fi
  '';

  # Inject secrets from 1Password via op inject.
  # On macOS with 1Password 8+, biometric auth via the desktop app is used automatically.
  # 1Password items needed (vault: PC):
  #   - "ssh-config"       : Secure Note (notesPlain)
  #   - "aws-credentials"  : Secure Note (notesPlain)
  #   - "k8s-config"       : Secure Note (notesPlain)
  #   - "deck-credentials" : Secure Note (notesPlain)
  home.activation.injectSecrets = lib.hm.dag.entryAfter [ "writeBoundary" "sshSetup" ] ''
    ${opHelpers}
    ${lib.concatMapStrings (i: ''
      mkdir -p "$(dirname "${hd}/${i.out}")"
      op_inject "${dotfiles}/op-templates/${i.tpl}" "${hd}/${i.out}"
    '') injects}
  '';
}
