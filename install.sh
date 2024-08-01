#!/bin/zsh

find_homebrew() {
  if [ -x /opt/homebrew/bin/brew ]; then
    echo "/opt/homebrew"
  elif [ -x /usr/local/bin/brew ]; then
    echo "/usr/local"
  elif [ -x $HOME/.homebrew/bin/brew ]; then
    echo "$HOME/.homebrew"
  else
    BREW_PATH=$(which brew 2>/dev/null)
    if [ -n "$BREW_PATH" ]; then
      dirname $(dirname $BREW_PATH)
    else
      echo ""
    fi
  fi
}




echo "Installing commandline tools..."
xcode-select --install

echo "Installing Brew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

HOMEBREW_PREFIX=$(find_homebrew)

if [ -z "$HOMEBREW_PREFIX" ]; then
  echo "Homebrew not found. Please install Homebrew first."
  exit 1
fi

eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

echo "Change directory to dotfiles"
DOTFILES_PATH="$HOME/dotfiles/"
cd $DOTFILES_PATH

echo "Install bundle from Brewfile"
brew bundle install --file Brewfile
source $HOMEBREW_PREFIX/opt/zinit/zinit.zsh

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
