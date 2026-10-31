# shellcheck shell=bash
# .NET SDK: repos nativos en Fedora y Arch; repo de Microsoft (con pin) en Ubuntu/Mint.

module_main() {
    adapter_prepare dotnet
    pkg_install_module dotnet
}
