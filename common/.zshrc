# ~/.zshrc gestionado por dotfiles (common/.zshrc).
# Ajustes propios de esta maquina: ~/.zshrc.local (no se versiona).

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode auto

# zsh-syntax-highlighting tiene que ser el ultimo plugin.
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)

# Entorno compartido con bash: nvm, pnpm, SDKMAN y .NET.
[[ -f "$HOME/.config/dotfiles/env.sh" ]] && source "$HOME/.config/dotfiles/env.sh"

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS SHARE_HISTORY

export EDITOR=vim
alias ll='ls -lah'

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
