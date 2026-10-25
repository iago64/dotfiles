#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

# shellcheck disable=SC1091
source /etc/os-release

# Linux Mint uses Ubuntu repositories; Docker and Microsoft packages need the
# Ubuntu base release rather than Mint's own version or codename.
if [[ ! -r /etc/upstream-release/lsb-release ]]; then
    printf 'No se encontro /etc/upstream-release/lsb-release para detectar la version base de Ubuntu.\n' >&2
    exit 1
fi
ubuntu_release="$(
    awk -F= '$1 == "DISTRIB_RELEASE" { gsub(/"/, "", $2); print $2; exit }' \
        /etc/upstream-release/lsb-release
)"
ubuntu_codename="${UBUNTU_CODENAME:-}"
if [[ -z "$ubuntu_release" || -z "$ubuntu_codename" ]]; then
    printf 'No se pudo detectar la version base de Ubuntu de Linux Mint.\n' >&2
    exit 1
fi

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
    aptitude vim emacs nano strace openssh-client curl htop tree wget terminator \
    xclip net-tools valgrind meld blueman gnupg zip jq ca-certificates \
    build-essential autotools-dev gcc gdb g++ python3 python3-pip \
    libcunit1-dev libcunit1 make cmake podman podman-compose zsh flatpak

# Configure Microsoft's Ubuntu repository for .NET and Visual Studio Code.
repo_file="$(mktemp)"
trap 'rm -f -- "$repo_file"' EXIT
curl -fsSL \
    "https://packages.microsoft.com/config/ubuntu/${ubuntu_release}/packages-microsoft-prod.deb" \
    -o "$repo_file"
sudo dpkg -i "$repo_file"
rm -f -- "$repo_file"
trap - EXIT
sudo apt-get update
sudo apt-get install -y dotnet-sdk-10.0

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
sudo chmod a+r /etc/apt/keyrings/packages.microsoft.gpg
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\n' \
    "$(dpkg --print-architecture)" |
    sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
sudo apt-get update
sudo apt-get install -y code

if [[ ! -d "$HOME/.sdkman" ]]; then
    curl -fsSL https://get.sdkman.io | bash
    set +u
    # shellcheck disable=SC1091
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    set -u
    sdk install java 21.0.10-amzn
    sdk install java 25.0.2-amzn
    sdk install quarkus
    sdk install gradle
fi

if [[ ! -d "$HOME/.nvm" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 24
nvm alias default 24
corepack enable pnpm

# Mint disables Snap by default; use Flatpak for desktop applications instead.
sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive flathub \
    com.usebruno.Bruno \
    com.obsproject.Studio \
    org.libretro.RetroArch \
    org.videolan.VLC \
    com.bitwarden.desktop

docker_keyring="/etc/apt/keyrings/docker.asc"
sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -f "$docker_keyring" ]]; then
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o "$docker_keyring"
    sudo chmod a+r "$docker_keyring"
fi
printf 'deb [arch=%s signed-by=%s] https://download.docker.com/linux/ubuntu %s stable\n' \
    "$(dpkg --print-architecture)" "$docker_keyring" "$ubuntu_codename" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "${USER:?}"

systemctl --user enable --now podman.socket

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
configure_zsh_environment

# Install JetBrains Toolbox without launching its GUI during setup.
toolbox_url="$(curl -fsSL \
    'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' |
    jq -er '.TBA[0].downloads.linux.link')"
curl -fsSL "$toolbox_url" | sudo tar -xzC /opt

# Instalar Discord de forma nativa (.deb)
discord_deb="$(mktemp --suffix=.deb)"
trap 'rm -f -- "$discord_deb"' EXIT
curl -fsSL "https://discord.com/api/download?platform=linux&format=deb" -o "$discord_deb"
sudo apt-get install -y "$discord_deb"
rm -f -- "$discord_deb"
trap - EXIT