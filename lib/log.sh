# shellcheck shell=bash
# Salida con formato comun para todos los scripts.

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    _c_reset=$'\e[0m'
    _c_step=$'\e[1;34m'
    _c_ok=$'\e[1;32m'
    _c_warn=$'\e[1;33m'
    _c_err=$'\e[1;31m'
else
    _c_reset=''
    _c_step=''
    _c_ok=''
    _c_warn=''
    _c_err=''
fi

log_step() { printf '\n%s==>%s %s\n' "$_c_step" "$_c_reset" "$*"; }
log_info() { printf '    %s\n' "$*"; }
log_ok() { printf '%s[ok]%s %s\n' "$_c_ok" "$_c_reset" "$*"; }
log_warn() { printf '%s[aviso]%s %s\n' "$_c_warn" "$_c_reset" "$*" >&2; }
log_error() { printf '%s[error]%s %s\n' "$_c_err" "$_c_reset" "$*" >&2; }

die() {
    log_error "$*"
    exit 1
}
