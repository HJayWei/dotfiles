#!/bin/zsh

DOTFILES_PATH="$HOME/.dotfiles/"

echo "Installing commandline tools..."
xcode-select --install

echo "Installing Brew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Change directory to dotfiles"
cd $HOME/.dotfiles/

echo "Install bundle from Brewfile"
brew bundle install


stow bat
bat cache --clear
bat cache --build
