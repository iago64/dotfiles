# Dotfiles

Este repositorio automatiza la preparacion de un entorno de trabajo en Linux.
Incluye scripts para instalar herramientas segun la distribucion y un
instalador que enlaza configuraciones personales guardadas en `common/` dentro
del directorio `$HOME`.

## Estructura

```text
.
├── install.sh
└── distros/
    ├── common.sh
    ├── ubuntu.sh
    ├── mint.sh
    ├── fedora.sh
    ├── arch.sh
    ├── ubuntu-network-manager.sh
    └── arch-hyprland.sh
```

- `install.sh` detecta la distribucion a partir de `/etc/os-release`, selecciona
  el instalador correspondiente y, al terminar, enlaza el contenido de
  `common/` en `$HOME`.
- `distros/*.sh` contiene la instalacion de paquetes y herramientas especifica
  de cada familia de distribuciones.
- `distros/common.sh` define las funciones compartidas: la configuracion del
  entorno de Zsh y la instalacion de JetBrains Toolbox (se descomprime en
  `/opt` y, si hay sesion grafica, se inicia en segundo plano para que se
  autoinstale y cree su entrada de menu).
- `common/` es el lugar para agregar los archivos y directorios de
  configuracion personales. Por ejemplo, `common/.bashrc` termina en
  `~/.bashrc`, y `common/.config/mi-app/` se integra en `~/.config/mi-app/`.

## Instalacion

1. Clona el repositorio en Linux y revisa los scripts de la distribucion que
   usas.
2. Agrega las configuraciones que quieras gestionar bajo `common/`. El
   instalador requiere que ese directorio exista: en el estado actual del
   repositorio aun no esta incluido, por lo que hay que crearlo antes de
   ejecutar el instalador.
3. Ejecuta desde la raiz del repositorio:

   ```bash
   ./install.sh
   ```

El instalador necesita Bash y privilegios `sudo` para las operaciones del
sistema. Actualiza paquetes, agrega repositorios y claves de terceros, instala
software, habilita servicios y puede modificar grupos de usuario. Para
entender exactamente que hara en tu sistema, lee primero `install.sh` y el
script de `distros/` que corresponda.

### Deteccion de distribucion

`install.sh` usa `ID` e `ID_LIKE` de `/etc/os-release` para elegir un script:

| Distribucion detectada | Script |
| --- | --- |
| Linux Mint (`linuxmint`) | `distros/mint.sh` |
| Ubuntu o Debian, y derivadas de Ubuntu/Debian | `distros/ubuntu.sh` |
| Fedora, y derivadas de Fedora/RHEL | `distros/fedora.sh` |
| Arch Linux, y derivadas de Arch | `distros/arch.sh` |

Si no puede identificar una familia soportada, termina con un error. El
instalador de Mint es independiente porque necesita la version base de Ubuntu
para configurar sus repositorios.

## Que instala

Los scripts incluyen, segun la distribucion, herramientas de desarrollo y
sistema como compiladores, depuradores, Python, editores, utilidades de red,
Docker o Podman, Zsh, Node.js y aplicaciones de escritorio. Tambien configuran
fuentes oficiales de paquetes cuando hace falta. Los detalles y las diferencias
estan en cada script:

- `distros/ubuntu.sh`: paquetes APT, .NET 10, SDKMAN (Java, Quarkus y Gradle),
  NVM con Node.js 24 y pnpm, Docker, Podman, Zsh/Oh My Zsh, aplicaciones Snap
  disponibles y JetBrains Toolbox. Si Snap no esta instalado, omite esa parte.
- `distros/mint.sh`: paquetes APT, .NET 10, Visual Studio Code, SDKMAN, NVM con
  Node.js 24 y pnpm, Docker, Podman, Zsh/Oh My Zsh, aplicaciones de Flathub,
  JetBrains Toolbox y Discord. Usa repositorios Ubuntu en lugar de los de Mint.
- `distros/fedora.sh`: paquetes DNF, .NET 10, Visual Studio Code, NVM con
  Node.js 24 y pnpm, Podman, aplicaciones de Flathub, SDKMAN y JetBrains
  Toolbox.
- `distros/arch.sh`: paquetes de Pacman, Java 21, NVM con Node.js 22 y pnpm,
  Docker, Zsh/Oh My Zsh, `yay` (si no esta instalado) y JetBrains Toolbox.

La seleccion de paquetes y versiones puede cambiar; consulta el script antes
de ejecutarlo. La instalacion de paquetes suele requerir conexion a Internet.

## Enlaces de configuracion

El instalador recorre las entradas inmediatas de `common/` y las refleja bajo
`$HOME`:

- Los archivos se enlazan simbolicamente.
- Los directorios se crean en el destino y se procesan recursivamente. Esto
  conserva otros archivos que ya existan en directorios como `~/.config`.
- Si el destino ya es el enlace correcto, no hace cambios.
- Si hay un archivo, enlace o directorio incompatible en el destino, lo mueve
  a un respaldo con sufijo `.backup-<fecha>-<pid>` antes de crear el enlace o
  integrar el contenido.
- `.gitkeep` se omite.

Volver a ejecutar `./install.sh` vuelve a intentar instalar/configurar los
paquetes y a sincronizar los enlaces. No es solamente un comando de enlaces.

## Scripts opcionales

Estos scripts no se ejecutan desde `install.sh`; se deben revisar y lanzar
manualmente desde la raiz del repositorio cuando se necesiten:

- `distros/ubuntu-network-manager.sh` reemplaza la configuracion de Netplan
  para usar NetworkManager, aplica el cambio y reinicia el servicio. Puede
  interrumpir la conexion de red actual.
- `distros/arch-hyprland.sh` actualiza Arch, instala Hyprland y el paquete
  `ml4w-hyprland` desde AUR mediante `yay`. Requiere que `distros/arch.sh` ya
  haya instalado `yay`.

## Zsh

Los instaladores de las distribuciones que preparan Zsh instalan Oh My Zsh y
llaman a `configure_zsh_environment`, definida en `distros/common.sh`. La
funcion agrega una seccion identificada por un marcador a `~/.zshrc`, con la
carga de NVM, pnpm y SDKMAN. Si existe la plantilla de Oh My Zsh, la usa como
base y, si ya existia un `.zshrc`, guarda una copia `.pre-dotfiles.bak` antes de
reemplazarlo. El marcador evita agregar repetidamente la seccion en ejecuciones
posteriores.
