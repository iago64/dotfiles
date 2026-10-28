#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm \
    vim emacs nano strace openssh curl htop tree wget terminator xclip bless \
    fastfetch net-tools valgrind meld bluez bluez-utils \
    base-devel gcc gdb python python-pip jdk21-openjdk cunit make cmake \
    docker jq

if [[ ! -d "$HOME/.nvm" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 22
nvm alias default 22
corepack enable pnpm

sudo systemctl enable --now docker
sudo usermod -aG docker "${USER:?}"

if ! command -v yay >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm git base-devel
    build_dir="$(mktemp -d)"
    trap 'rm -rf -- "$build_dir"' EXIT
    git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
    (
        cd "$build_dir/yay"
        makepkg -si --noconfirm
    )
    rm -rf -- "$build_dir"
    trap - EXIT
fi

# Install JetBrains Toolbox and launch it once if a graphical session exists.
install_jetbrains_toolbox

# zsh es lo ultimo que se instala.
sudo pacman -S --needed --noconfirm zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
configure_zsh_environment
