{ pkgs, dotfiles, ... }: {
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
  };

  home.file.".emacs.d/early-init.el".source = "${dotfiles}/.emacs.d/early-init.el";
  home.file.".emacs.d/init.el".source = "${dotfiles}/.emacs.d/init.el";
  home.file.".emacs.d/lang".source = "${dotfiles}/.emacs.d/lang";
}
