#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

# shellcheck disable=SC1091
source /etc/os-release

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
    aptitude vim emacs nano strace openssh-client curl htop tree wget terminator \
    xclip net-tools valgrind meld blueman gnupg zip jq ca-certificates \
    build-essential autotools-dev gcc gdb g++ python3 python3-pip \
    libcunit1-dev libcunit1 make cmake

# Microsoft publica el paquete de configuracion por distribucion y version.
case "${ID:-}" in
    ubuntu|debian)
        package_id="$ID"
        ;;
    *)
        printf 'No se instala .NET: no hay repositorio Microsoft configurado para %s.\n' \
            "${ID:-desconocida}" >&2
        package_id=''
        ;;
esac
if [[ -n "$package_id" ]]; then
    package_file="$(mktemp)"
    trap 'rm -f -- "$package_file"' EXIT
    curl -fsSL \
        "https://packages.microsoft.com/config/${package_id}/${VERSION_ID}/packages-microsoft-prod.deb" \
        -o "$package_file"
    sudo dpkg -i "$package_file"
    sudo apt-get update
    sudo apt-get install -y dotnet-sdk-10.0
    rm -f -- "$package_file"
    trap - EXIT
fi

# SDKMAN manages Java, Quarkus and Gradle independently of the OS packages.
if [[ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    rm -rf "$HOME/.sdkman"
    curl -fsSL "https://get.sdkman.io" | bash
fi
set +u
# shellcheck disable=SC1091
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 21.0.10-amzn
sdk install java 25.0.2-amzn
sdk install quarkus
sdk install gradle
set -u

if [[ ! -d "$HOME/.nvm" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
nvm install 24
nvm alias default 24
corepack enable pnpm

if command -v snap >/dev/null 2>&1; then
    sudo snap install discord
    sudo snap install obs-studio
    sudo snap install vlc
    sudo snap install code --classic
else
    printf 'snap no esta instalado; se omiten las aplicaciones Snap.\n'
fi

docker_repo_id="${ID:-}"
docker_codename="${VERSION_CODENAME:-}"
case "${ID:-}" in
    ubuntu)
        docker_repo_id="ubuntu"
        docker_codename="${UBUNTU_CODENAME:-$docker_codename}"
        ;;
    debian)
        docker_repo_id="debian"
        ;;
    *)
        case "${ID_LIKE:-}" in
            *ubuntu*)
                docker_repo_id="ubuntu"
                docker_codename="${UBUNTU_CODENAME:-$docker_codename}"
                ;;
            *debian*)
                docker_repo_id="debian"
                ;;
            *)
                printf 'No se pudo determinar una distribucion compatible con Docker.\n' >&2
                exit 1
                ;;
        esac
        ;;
esac
if [[ -z "$docker_codename" ]]; then
    printf 'No se pudo determinar el codename para el repositorio Docker.\n' >&2
    exit 1
fi

# Docker's official repository is needed for the Docker Engine packages.
sudo install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    sudo curl -fsSL "https://download.docker.com/linux/${docker_repo_id}/gpg" \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
fi

printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/%s %s stable\n' \
    "$(dpkg --print-architecture)" "$docker_repo_id" "$docker_codename" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "${USER:?}"

sudo apt-get install -y podman podman-compose zsh
systemctl --user enable --now podman.socket

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
configure_zsh_environment

# Install JetBrains Toolbox and launch it once if a graphical session exists.
install_jetbrains_toolbox
