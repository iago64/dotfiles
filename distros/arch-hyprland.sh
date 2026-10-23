#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v yay >/dev/null 2>&1; then
    printf 'Instale yay ejecutando distros/arch.sh antes de este script.\n' >&2
    exit 1
fi

sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm hyprland
yay -S --needed --noconfirm ml4w-hyprland
