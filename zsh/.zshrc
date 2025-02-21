# ---- Zinit ---- #
source $HOMEBREW_PREFIX/opt/zinit/zinit.zsh

# Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Package from Oh My Zsh
zinit snippet OMZ::lib/completion.zsh
zinit snippet OMZ::lib/history.zsh
zinit snippet OMZ::lib/key-bindings.zsh
zinit snippet OMZ::lib/theme-and-appearance.zsh
zinit snippet OMZ::lib/clipboard.zsh
zinit snippet OMZ::lib/functions.zsh
zinit snippet OMZ::lib/termsupport.zsh
zinit snippet OMZ::lib/git.zsh
zinit snippet OMZ::plugins/git/git.plugin.zsh

# Lazy Load Plugins
zinit ice wait'!' lucid
zinit light zsh-users/zsh-completions

zinit ice wait lucid
zinit light zsh-users/zsh-history-substring-search

zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting

zinit ice wait lucid
zinit load zsh-users/zsh-autosuggestions
zinit load djui/alias-tips

# Activate the built-in autocomplete system in Zsh
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit;
else
  compinit -C;
fi;

# Enhance autocomplete performance by utilizing cache
zstyle ':completion::complete:*' use-cache 1

# About command history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Avoid duplicate command history entries
setopt HIST_IGNORE_DUPS
unsetopt share_history



# ---- Custom ---- #

# Alias Command
alias ls='eza --icons=always'
alias ll='ls -lhg'
alias lt='eza --tree --level=2 --long --icons --git'
alias clr='clear'
alias grep='grep --color=auto'

# ---- Fuzzy Finder (FZF) ---- #
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Use fd instead of fzf
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# FZF Git
source ~/.config/fzf-git/fzf-git.sh

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# Theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:-1,fg+:#d0d0d0,bg:-1,bg+:#262626
  --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
  --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
  --color=border:#394b50,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="◆" --separator="─" --scrollbar="│"
  --info="right"'

# ---- Bat (better cat) ---- #

export BAT_THEME="Dracula"

alias cat="bat --style plain"
alias catn="bat"

# ---- Zoxide (better cd) ---- #

source <(zoxide init zsh)

alias cd="z"

# ---- asdf ---- #
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# ---- Rust ---- #
export PATH=$PATH:$HOME/.cargo/bin

# ---- Copy command with OSC 52 ---- #
copy() {
    local content
    if [ -t 0 ]; then
        if [ $# -eq 0 ]; then
            echo "Usage: copy <filename> or pipe content to copy"
            return 1
        fi
        content=$(cat "$1")
    else
        content=$(cat)
    fi

    local encoded
    encoded=$(echo -n "$content" | base64 | tr -d '\n')
    echo -en "\e]52;c;$encoded\a"
    echo "Content copied to clipboard!"
}
