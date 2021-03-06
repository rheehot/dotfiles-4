# Make the $path array have unique values.
typeset -U path

if [ -e /proc/version ] && grep -q Microsoft /proc/version; then
  # See https://github.com/microsoft/WSL/issues/352
  if [[ "$(umask)" = *'000' ]]; then
    if [ -e /etc/login.defs ] && grep -q '^[[:space:]]*USERGROUPS_ENAB[[:space:]]\{1,\}yes' /etc/login.defs; then
      umask 002
    else
      umask 022
    fi
  fi
fi

if command -v brew >/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
fi

# See ZSHZLE(1).
#
# If one of the VISUAL or EDITOR environment variables contain the string `vi'
# when the shell starts up then it will be `viins', otherwise it will be
# `emacs'.
#
# Select keymap `emacs' for any operations by the current command
bindkey -e

# Use Zinit
if [ ! -e "$HOME/.zinit/bin/zinit.zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
fi
source "$HOME/.zinit/bin/zinit.zsh"

# Additional completion definitions for Zsh
if is-at-least 5.3; then
  zinit ice lucid wait'0' blockf
else
  zinit ice blockf
fi
zinit light zsh-users/zsh-completions
# Simple standalone Zsh theme
zinit light yous/lime
# A lightweight start point of shell configuration
zinit light yous/vanilli.sh
# Jump quickly to directories that you have visited "frecently." A native ZSH
# port of z.sh.
zinit light agkozak/zsh-z
# Syntax-highlighting for Zshell – fine granularity, number of features, 40 work
# hours themes (short name F-Sy-H)
if is-at-least 5.3; then
  zinit ice lucid wait'0' atinit'zpcompinit; zpcdreplay'
else
  autoload -Uz compinit
  compinit
  zinit cdreplay -q
fi
zinit light zdharma/fast-syntax-highlighting
# ZSH port of Fish shell's history search feature. zsh-syntax-highlighting must
# be loaded before this.
is-at-least 5.3 && zinit ice lucid wait'[[ $+functions[_zsh_highlight] -ne 0 ]]' atload' \
  zmodload zsh/terminfo; \
  [ -n "${terminfo[kcuu1]}" ] && bindkey "${terminfo[kcuu1]}" history-substring-search-up; \
  [ -n "${terminfo[kcud1]}" ] && bindkey "${terminfo[kcud1]}" history-substring-search-down; \
  bindkey -M emacs "^P" history-substring-search-up; \
  bindkey -M emacs "^N" history-substring-search-down; \
  bindkey -M vicmd "k" history-substring-search-up; \
  bindkey -M vicmd "j" history-substring-search-down; \
'
zinit light zsh-users/zsh-history-substring-search
if ! is-at-least 5.3; then
  zmodload zsh/terminfo
  [ -n "${terminfo[kcuu1]}" ] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
  [ -n "${terminfo[kcud1]}" ] && bindkey "${terminfo[kcud1]}" history-substring-search-down
  bindkey -M emacs '^P' history-substring-search-up
  bindkey -M emacs '^N' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi

# Load autojump
if command -v autojump >/dev/null; then
  if [ -f "$HOME/.autojump/etc/profile.d/autojump.sh" ]; then
    source "$HOME/.autojump/etc/profile.d/autojump.sh"
  elif [ -f /etc/profile.d/autojump.zsh ]; then
    source /etc/profile.d/autojump.zsh
  elif [ -f /usr/share/autojump/autojump.zsh ]; then
    source /usr/share/autojump/autojump.zsh
  elif [ -n "$BREW_PREFIX" ]; then
    if [ -f "$BREW_PREFIX/etc/autojump.sh" ]; then
      source "$BREW_PREFIX/etc/autojump.sh"
    fi
  fi
elif [ -f "$HOME/.autojump/etc/profile.d/autojump.sh" ]; then
  source "$HOME/.autojump/etc/profile.d/autojump.sh"
fi

# Load fzf
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh

  # fshow - git commit browser
  fshow() {
    git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(green)%cr%C(reset)" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 |
                 xargs -I % sh -c 'git show --color=always %'" \
      --bind "ctrl-m:execute:
        (grep -o '[a-f0-9]\{7\}' | head -1 |
        xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
        {}
FZF-EOF"
  }
fi

# Load chruby
if [ -e /usr/local/share/chruby/chruby.sh ]; then
  source /usr/local/share/chruby/chruby.sh
  source /usr/local/share/chruby/auto.sh
elif [ -n "$BREW_PREFIX" ]; then
  if [ -e "$BREW_PREFIX/opt/chruby/share/chruby/chruby.sh" ]; then
    source "$BREW_PREFIX/opt/chruby/share/chruby/chruby.sh"
    source "$BREW_PREFIX/opt/chruby/share/chruby/auto.sh"
  fi
fi

# Load rbenv
if command -v rbenv >/dev/null || [ -e "$HOME/.rbenv" ]; then
  eval "$(rbenv init - zsh)"
fi

# Load pyenv
if command -v pyenv >/dev/null; then
  eval "$(pyenv init - zsh)"
  if command -v pyenv-virtualenv-init >/dev/null; then
    eval "$(pyenv virtualenv-init - zsh)"
  fi
elif [ -e "$HOME/.pyenv" ]; then
  eval "$(pyenv init - zsh)"
  if [ -e "$HOME/.pyenv/plugins/pyenv-virtualenv" ]; then
    eval "$(pyenv virtualenv-init - zsh)"
  fi
fi

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
  source "$HOME/.rvm/scripts/rvm"

  if [[ "$(type rvm | head -n 1)" == "rvm is a shell function" ]]; then
    # Add RVM to PATH for scripting
    case ":$PATH:" in
      *":$HOME/.rvm/bin:"*)
        ;;
      *)
        export PATH="$PATH:$HOME/.rvm/bin"
    esac
    export rvmsudo_secure_path=1

    # Use right RVM gemset when using tmux
    if [ -n "$TMUX" ]; then
      rvm use default
      pushd -q ..
      popd -q
    fi
  fi
fi

# Enable keychain
if command -v keychain >/dev/null; then
  KEY=''
  if [ -f "$HOME/.ssh/id_ed25519" ]; then
    KEY='id_ed25519'
  elif [ -f "$HOME/.ssh/id_rsa" ]; then
    KEY='id_rsa'
  fi
  if [ -n "$KEY" ]; then
    if [ "$(uname)" = 'Darwin' ]; then
      eval `keychain --eval --quiet --agents ssh --inherit any $KEY`
    else
      eval `keychain --eval --quiet --agents ssh $KEY`
    fi
  fi
  unset KEY
fi

# Unset local functions and variables
unset BREW_PREFIX

# Define aliases
if [ -f "$HOME/.aliases" ]; then
  source "$HOME/.aliases"
fi

# Source local zshrc
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
