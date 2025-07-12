# Update .env
vi "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.env

# Setup for Zsh
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zlogin "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zlogout "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zpreztorc "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zprofile "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zshenv "$HOME"
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zshrc "$HOME"
mkdir -p "$HOME"/.zprezto
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/prezto/init.zsh "$HOME"/.zprezto
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/prezto/modules "$HOME"/.zprezto

# Setup for SSH
rm -rf "$HOME"/.ssh
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.ssh "$HOME"

# Setup for anyenv
anyenv install --init

# Setup for Emacs
ln -s "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.emacs.d "$HOME"
