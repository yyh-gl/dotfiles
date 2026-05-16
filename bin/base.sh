# Update .env.public
vi "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.env.public

# Setup for SSH
cp -rf "$HOME"/workspaces/github.com/yyh-gl/dotfiles/depended-repositories/dotfiles-private/.ssh "$HOME"

# Setup for Emacs
cp -rf "$HOME"/workspaces/github.com/yyh-gl/dotfiles/.emacs.d/. "$HOME"/.emacs.d/
