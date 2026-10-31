#!/usr/bin/env bash
# Prepara un contenedor limpio para probar el instalador en CI: instala sudo y
# git, y crea un usuario "dev" con sudo sin contrasena (install.sh no corre
# como root). Uso: ci/prepare-container.sh <directorio del repo>
set -Eeuo pipefail

repo_dir="${1:?Uso: $0 <directorio del repo>}"

# shellcheck disable=SC1091
source /etc/os-release
case "$ID" in
    ubuntu | linuxmint)
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y sudo git curl ca-certificates
        ;;
    fedora)
        dnf install -y sudo git shadow-utils
        ;;
    arch)
        pacman -Syu --noconfirm --needed sudo git
        ;;
    *)
        printf 'Contenedor no soportado: %s\n' "$ID" >&2
        exit 1
        ;;
esac

id dev >/dev/null 2>&1 || useradd --create-home --shell /bin/bash dev
printf 'dev ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/dev
chmod 0440 /etc/sudoers.d/dev

rm -rf /home/dev/dotfiles
cp -a "$repo_dir" /home/dev/dotfiles
chown -R dev:dev /home/dev/dotfiles
