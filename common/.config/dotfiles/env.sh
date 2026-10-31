# shellcheck shell=sh disable=SC1091
# Entorno compartido por bash y zsh. Lo cargan common/.zshrc y ~/.bashrc.
# Gestionado por dotfiles: los cambios propios de una maquina van en
# ~/.zshrc.local o al final de ~/.bashrc.

_dotfiles_path_prepend() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

_dotfiles_path_prepend "$HOME/.local/bin"

# Node.js (nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [ -n "${BASH_VERSION:-}" ] && [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
_dotfiles_path_prepend "$PNPM_HOME"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# .NET
export DOTNET_CLI_TELEMETRY_OPTOUT=1
_dotfiles_path_prepend "$HOME/.dotnet/tools"

export PATH
unset -f _dotfiles_path_prepend

# SDKMAN (Java, Gradle, Quarkus): debe ir al final.
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && . "$SDKMAN_DIR/bin/sdkman-init.sh"
