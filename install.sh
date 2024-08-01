#!/bin/zsh

DOTFILES_PATH="$HOME/dotfiles/"

echo "Installing commandline tools..."
xcode-select --install

echo "Installing Brew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Change directory to dotfiles"
cd $DOTFILES_PATH

echo "Install bundle from Brewfile"
brew bundle install --file Brewfile
source /opt/homebrew/opt/zinit/zinit.zsh

echo "Install Commit Mono Nerd Font"
brew install --cask font-commit-mono-nerd-font

echo "Install bundle from BrewCask"
brew bundle install --file BrewCask

echo "Stow alacritty configuration"
stow alacritty

echo "Stow zsh configuration"
stow zsh

echo "Stow git configuration"
stow git

echo "Stow NeoVim onfiguration"
stow nvim

echo "Stow Bat configuration"
stow bat
bat cache --clear
bat cache --build

echo "Stow Docker configuration"
stow docker

echo "Stow Espanso configuration"
stow espanso

echo "Stow Zellij configuration"
stow zellij

echo "Install Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
