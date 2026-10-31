# shellcheck shell=bash
# Node.js con nvm y pnpm con corepack.

module_main() {
    export NVM_DIR="$HOME/.nvm"
    if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
        # PROFILE=/dev/null: la carga de nvm la hace common/.config/dotfiles/env.sh.
        download "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" |
            PROFILE=/dev/null bash
    fi

    # nvm no es compatible con set -u.
    set +u
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
    nvm install "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
    nvm use default

    # Node 25+ ya no trae corepack incluido.
    if ! command -v corepack >/dev/null 2>&1; then
        npm install -g corepack
    fi
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    corepack enable pnpm
    log_info "Node $(node --version), pnpm $(pnpm --version)"
    set -u
}
