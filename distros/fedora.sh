#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

sudo dnf -y update
sudo dnf install -y \
    vim emacs nano strace openssh curl htop tree wget terminator xclip bless \
    fastfetch net-tools openssh-server valgrind meld jq \
    kernel-devel kernel-headers gcc gcc-c++ gdb python3 python3-pip \
    adoptium-temurin-java-repository dotnet-sdk-10.0 CUnit make cmake \
    podman podman-compose zsh flatpak

if [[ ! -d "$HOME/.nvm" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 24
nvm alias default 24
corepack enable pnpm

systemctl --user enable --now podman.socket

# Configure the official Visual Studio Code repository.
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf -y install code

sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive flathub \
    com.discordapp.Discord \
    com.usebruno.Bruno \
    com.obsproject.Studio \
    org.libretro.RetroArch \
    org.videolan.VLC \
    com.bitwarden.desktop

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# SDKMAN manages Java, Quarkus and Gradle independently of the OS packages.
if [[ ! -d "$HOME/.sdkman" ]]; then
    curl -fsSL "https://get.sdkman.io" | bash
    # shellcheck disable=SC1091
    set +u
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    set -u
    sdk install java 21.0.10-amzn
    sdk install java 25.0.2-amzn
    sdk install quarkus
    sdk install gradle
fi
configure_zsh_environment

# Install JetBrains Toolbox without launching its GUI during setup.
toolbox_url="$(curl -fsSL \
    'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' |
    jq -er '.TBA[0].downloads.linux.link')"
curl -fsSL "$toolbox_url" | sudo tar -xzC /opt
