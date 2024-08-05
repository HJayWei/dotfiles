# ---- HomeBrew ---- #
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

HOMEBREW_PREFIX=$(find_homebrew)

if [ -z "$HOMEBREW_PREFIX" ]; then
  echo "Homebrew not found. Please install Homebrew first."
  exit 1
fi

eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"


# Added by OrbStack: command-line tools and integration
# Comment this line if you don't want it to be added again.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Proactively load the zshrc file due to an issue with Neovide.
source ~/.zshrc
