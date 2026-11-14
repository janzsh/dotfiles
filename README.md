# dotfiles

Mi máquina entera como código: NixOS con flakes, home-manager, dos compositores
Wayland intercambiables y un shell de escritorio escrito a mano en QML.
Un solo `nixos-rebuild switch` reproduce el sistema, y el aspecto de todo se
cambia en caliente con un comando.

```
nixos-rebuild switch --flake .#onirical     # sistema + home, reproducible
theme set frappe                            # recolorea sway, hyprland, kitty, shell y prompt al instante
```

## Lo que hay aquí

### Un tema, seis destinos
`theme set <nombre>` lee `config/theme/themes/<nombre>/theme.json` y renderiza
plantillas (`{{clave}}` sustituida con `jq`) para **sway, Hyprland, kitty,
starship, fzf y Quickshell**. Cada destino se recarga en vivo: `swaymsg` para
sway, `hyprctl reload` para Hyprland, `SIGUSR1` a kitty, y Quickshell vigila su
`Theme.qml` y se recolorea solo. Añadir un tema es copiar una carpeta y editar
los colores. Hoy hay dos: `frappe` (Catppuccin Frappé) y `evernight` (con
wallpaper).

### Quickshell: el escritorio, sin barras de terceros
~5.800 líneas de QML que reemplazan lo que normalmente son cinco programas
distintos: lanzador, menú de apagado, pantalla de bloqueo, historial del
portapapeles, OSD de volumen y brillo, dock, selector de ventanas, widgets de
red, bluetooth, batería, medios, CPU/RAM y calendario, además de pomodoro,
alarmas, cuenta atrás y cronómetro con sonidos propios.

- **Agnóstico del compositor.** El shell no sabe si corre sobre sway o Hyprland:
  un *bridge* (`wm-state-bridge.sh`) traduce los eventos de cada uno
  (`swaymsg subscribe`, o el socket de Hyprland vía `socat`) al mismo
  `~/.cache/wm-state.json`, y Quickshell solo lee ese archivo.
- **El dock se adapta.** En Hyprland es una píldora que flota sobre las ventanas
  sin reservar espacio y se esconde sola; en sway usa una franja de 3 px con
  hover. Son dos ventanas layer-shell separadas para evitar el bucle
  enter/leave que provoca cambiar la máscara de entrada con el cursor encima.
- **Widget de consumo de IA.** `ai-usage.py` suma los tokens de Claude Code
  leyendo `~/.claude/projects/**/*.jsonl` (deduplicando por id de mensaje) y la
  actividad de Antigravity desde su sqlite.
- **Greeter propio.** El login (`greetd`) es un `shell.qml` que reutiliza el
  mismo `Theme.qml` y `LoadingRing.qml` que el escritorio. Las sesiones
  disponibles se extraen de los `.desktop` del sistema en tiempo de build.

### Dos compositores, una config
- **sway**: `config/sway` con scripts para autotiling, capturas por región,
  redimensionado y cambio de layout.
- **Hyprland**: configuración **en Lua**, partida en módulos de una sola
  responsabilidad (`theme`, `env`, `monitors`, `input`, `look`, `layouts`,
  `rules`, `binds`, `autostart`) con layout `monocle` propio. Corre bajo UWSM
  y define su propio `hyprland-session.target` para que los portales de
  systemd arranquen.

### Neovim modular (lazy.nvim)
Pensado para que romper algo no obligue a abrir un archivo de miles de líneas:

- **Un plugin, un archivo**, agrupados en `plugins/{ui,editor,lsp,coding,lang}`.
- **Un lenguaje, un archivo** en `plugins/lang/`: cada uno aporta su parte a
  treesitter, lspconfig y conform, que lazy fusiona solo. Quitar un lenguaje es
  borrar su archivo. Ajustes de buffer en `ftplugin/`.
- **Sin mason.** Los LSP y formateadores salen de Nix (`extraPackages`),
  porque los binarios descargados no corren bien en NixOS.
- Atajos dentro de cada spec (`keys = {}`), así un plugin roto no tumba el
  arranque. `lazy-lock.json` versionado. Catppuccin Frappé.

Lenguajes: Go (gopls + goimports + delve), Python (basedpyright + ruff +
debugpy), Lua (lua_ls + stylua + lazydev), TOML (taplo), JSON, SQL (sqlfluff).
Cada lenguaje añade también su depurador (nvim-dap) y su adaptador de tests
(neotest). Los atajos aparecen en which-key al pulsar `<leader>`.

## Cómo está montado

```
flake.nix                    host `onirical` (nixos-unstable) + home-manager como módulo de NixOS
nix/
  hosts/onirical/            configuration.nix (solo imports) + hardware
  modules/                   sistema: core, desktop, gaming, containers
    dev/ multimedia/ browser/  paquetes de usuario agrupados por tema
  home/janz/                 un .nix por programa (git, zsh, kitty, neovim, ...)
config/                      lo que se edita sin rebuild
  quickshell/ sway/ hyprland/ nvim/ kitty/ theme/ greeter/
```

La decisión central: **`config/` no pasa por la tienda de Nix.** Cada directorio
se enlaza con `mkOutOfStoreSymlink` directo al repo, así que editar un `.qml`,
un `.lua` o un tema se ve al instante (Quickshell recarga solo, los
compositores con `mod+shift+c`) sin esperar un rebuild. Nix se queda con lo que
debe ser reproducible: paquetes, servicios y los enlaces mismos. La única
excepción es el greeter, que se copia a la tienda porque corre antes de que
exista sesión de usuario.

`pkgs` se construye una sola vez en `flake.nix` (con `allowUnfree` y los
overlays de Rust y Zig) y se comparte con home-manager (`useGlobalPkgs`).

## Usarlo

```sh
git clone git@github.com:janzsh/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo nixos-rebuild switch --flake .#onirical
```

Las rutas de los enlaces apuntan a `/home/janz/dotfiles`; si lo clonas en otro
sitio, ajusta los `mkOutOfStoreSymlink` en `nix/home/janz/`. `hardware-configuration.nix`
es de mi máquina: regenera el tuyo con `nixos-generate-config`.

## Licencia

[MIT](LICENSE).
