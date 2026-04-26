# Update .env.public
vi "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.env.public

# Setup for Zsh
cp -f "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zlogin "$HOME"/
cp -f "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zlogout "$HOME"/
cp -f "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zpreztorc "$HOME"/
cp -f "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zprofile "$HOME"/
cp -f "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zshenv "$HOME"/
cp -f "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.zshrc "$HOME"/
mkdir -p "$HOME"/.zprezto
rm -f "$HOME"/.zprezto/init.zsh
rm -rf "$HOME"/.zprezto/modules
cp -f "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/prezto/init.zsh "$HOME"/.zprezto
cp -rf "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/prezto/modules "$HOME"/.zprezto

# Setup for SSH
cp -rf "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.ssh "$HOME"

# Setup for anyenv
anyenv install --init

# Setup for Emacs
cp -rf "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.emacs.d/. "$HOME"/.emacs.d/
