{ lib, config, dotfiles, pkgs, ... }:
let
  hd = config.home.homeDirectory;
  op = "${pkgs._1password-cli}/bin/op";
in {
  home.packages = [ pkgs._1password-cli ];

  home.activation.sshSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${hd}/.ssh/keys"
    chmod 700 "${hd}/.ssh"
    chmod 700 "${hd}/.ssh/keys"
    cp -f "${dotfiles}/.ssh/keys/hobigon-k8s-master.pub" "${hd}/.ssh/keys/hobigon-k8s-master.pub"
    cp -f "${dotfiles}/.ssh/keys/hobigon-k8s-worker.pub" "${hd}/.ssh/keys/hobigon-k8s-worker.pub"
    cp -f "${dotfiles}/.ssh/keys/hobigon-wsl.pub"        "${hd}/.ssh/keys/hobigon-wsl.pub"
    chmod 644 "${hd}/.ssh/keys/hobigon-k8s-master.pub" "${hd}/.ssh/keys/hobigon-k8s-worker.pub" "${hd}/.ssh/keys/hobigon-wsl.pub"
  '';

  # Inject secrets from 1Password via op inject.
  # On macOS with 1Password 8+, biometric auth via the desktop app is used automatically.
  # 1Password items needed (vault: PC):
  #   - "SSH Config"        : Secure Note
  #   - "AWS"               : Secure Note
  #   - "Kubernetes Config" : Secure Note
  #   - "Deck Credentials"  : Secure Note
  home.activation.injectSecrets = lib.hm.dag.entryAfter [ "writeBoundary" "sshSetup" ] ''
    ${op} inject -i "${dotfiles}/op-templates/ssh-config.tpl" \
               -o "${hd}/.ssh/config" --force
    chmod 600 "${hd}/.ssh/config"

    mkdir -p "${hd}/.aws"
    ${op} inject -i "${dotfiles}/op-templates/aws-credentials.tpl" \
               -o "${hd}/.aws/credentials" --force
    chmod 600 "${hd}/.aws/credentials"

    mkdir -p "${hd}/.kube"
    ${op} inject -i "${dotfiles}/op-templates/kube-config.tpl" \
               -o "${hd}/.kube/config" --force
    chmod 600 "${hd}/.kube/config"

    mkdir -p "${hd}/.local/share/deck"
    ${op} inject -i "${dotfiles}/op-templates/deck-credentials.tpl" \
               -o "${hd}/.local/share/deck/credentials.json" --force
    chmod 600 "${hd}/.local/share/deck/credentials.json"
  '';
}
