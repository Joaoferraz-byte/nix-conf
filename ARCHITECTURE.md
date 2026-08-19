# Arquitetura do `nix-conf`

## 1. Escopo e conclusão

`nix-conf` é a raiz de composição declarativa dos hosts NixOS. O flake-parts publica configurações NixOS, módulos system-side e uma composição Home Manager por usuário. A sessão gráfica usa Hyprland com UWSM; o shell visual é o Serpantinum, adaptado pelo repositório `shell-conf`; o editor é publicado por `vim-conf`; e os dados editáveis de Xournal++ vêm de `xournal-conf`.

A arquitetura segue três regras:

> **Um owner por concern, uma camada de avaliação por tipo de estado e um contrato público entre repositórios.**

NixOS owns compositor, UWSM, drivers, keyd, portais e serviços privilegiados. Home Manager owns programas de usuário, arquivos XDG e serviços de usuário. `shell-conf` owns Serpantinum, QuickShell, Matugen, wallpaper UI e adaptadores de tema. `vim-conf` owns NixVim. `xournal-conf` owns dados editáveis de Xournal++. `Wallpapers` owns imagens.

## 2. Fluxo de composição

```text
flake inputs
  -> flake-parts outputs
    -> host roots
      -> NixOS system features
        -> common desktop composition
          -> Home Manager user profile
            -> Serpantinum user services and application adapters
```

A composição comum recebe `userName` e `hostName` por `extraSpecialArgs`. Os dois hosts usam a mesma base de shell; apenas `hostProfile` e capacidades de interface variam.

| Host | Perfil | Diferenças legítimas |
|---|---|---|
| `latitude` | `laptop` | Intel, energia, ext4 e Wi-Fi/Bluetooth prioritários |
| `myMachine` | `desktop` | GPU/monitores, Btrfs, virtualização e Bluetooth opcional na interface |

## 3. Fronteiras entre repositórios

| Repositório/input | Contrato | Owner |
|---|---|---|
| `nix-conf` | hosts, módulos NixOS, composição HM, scripts e documentação | sistema e integração |
| `shell-conf` | `packages`, `nixosModules.default`, `homeManagerModules.default` | Serpantinum/QuickShell/Matugen |
| `vim-conf` | módulo e pacote NixVim | editor |
| `xournal-conf` | XML, INI, GPL e TeX | dados de Xournal++ |
| `Wallpapers` | imagens | catálogo de assets |
| `home-manager` | módulo HM NixOS | ambiente de usuário |
| `zen-browser-flake` | módulo e pacote Zen | navegador |

O flake do `nix-conf` importa `shell-conf` e não contém inputs operacionais de shells legados. O repositório `shell-conf` mantém uma cópia revisada do source Serpantinum necessário porque o upstream não oferece flake NixOS estável.

## 4. Hyprland, niri, Noctalia e Serpantinum

`modules/features/hyprland.nix` habilita `programs.hyprland.enable = true`, `withUWSM = true` e o portal Hyprland. `modules/features/niri.nix` habilita o niri para `latitude`; o display manager seleciona a sessão correta por `desktop.profile.compositor`. Home Manager não inicia um segundo lifecycle do compositor. `home/livara/session.nix` possui apenas `hypridle`, diretório de screenshots e limpeza segura de arquivos Lua legados.

O shell visível é selecionado por `desktop.profile.shellBackend`, atualmente `noctalia`. O módulo upstream do Noctalia é anexado ao target systemd Wayland da sessão. O `shell-conf` continua instalado como adaptador de Matugen, contratos de aplicativos, scripts canônicos e geração do KDL; quando Noctalia está ativo, `serpantinum-shell.service` e `serpantinum-wallpaper-daemon.service` não são criados.

| Concern | Owner |
|---|---|
| Login e compositor | NixOS niri ou Hyprland/UWSM |
| Idle/lock policy | `home/livara/session.nix` + hypridle |
| Shell surface, launcher e panels | Noctalia + IPC documentado |
| Wallpaper selection and transitions | Noctalia |
| Wallpaper catalog | `Wallpapers` + `sync.nix` |
| Matugen and application adapters | `shell-conf` / `sync-serpantinum-themes` |
| Privileged input remapping | `modules/features/keyd.nix` |

## 5. Serpantinum como adaptador NixOS

A fonte Serpantinum é vendorizada em `shell-conf` como uma árvore local revisada e adaptada arquivo a arquivo. O `shell-conf` não executa um instalador da fonte original nem depende de um flake fornecido por ela: o flake local é somente a fronteira NixOS/Home Manager que publica a cópia adaptada, dependências, serviços e estado mutável.

O módulo Home Manager declara opções tipadas:

```text
programs.serpantinum.enable
programs.serpantinum.shellBackend
programs.serpantinum.wallpaperDirectory
programs.serpantinum.hostProfile
programs.serpantinum.networkWidgets
programs.serpantinum.bluetoothWidgets
```

O shell recebe essas opções por `SERPANTINUM_*`. O QML detecta hardware de rede por capacidade e não pelo hostname; o perfil controla pequenas decisões de apresentação, especialmente Wi-Fi/Bluetooth no notebook. Bluetooth é habilitado no NixOS somente em `latitude`, com `hardware.bluetooth` e `powerOnBoot`; o applet Blueman permanece desabilitado porque o painel Serpantinum é o único owner da interface. `myMachine` recebe `hardware.bluetooth.enable=false` e `SERPANTINUM_BLUETOOTH_WIDGETS=0`, não cria o pill Bluetooth e não inicia scan pelo `qs_manager.sh` ou pelo `NetworkPopup`.

## 6. Tema adaptativo

Matugen é executado uma vez por troca de wallpaper e gera outputs mutáveis. Templates estáticos vivem no Nix store; os arquivos resultantes não são links para o store. O fluxo é:

```text
image under WALLPAPER_DIR
  -> Noctalia wallpaper_changed hook
    -> matugen image
      -> Matugen token JSON
      -> Noctalia custom palette JSON
      -> QuickShell JSON when Serpantinum backend is selected
      -> Hyprland colors.conf when the Hyprland adapter is active
    -> GTK3/GTK4 CSS
    -> Qt palettes and QSS
    -> WezTerm colors (native Lua template)
    -> Neovim Lua palette
    -> Firefox/Zen userChrome.css
    -> ZenNotes custom theme
    -> Xournal++ GPL palette + colorPalette setting
    -> Vesktop/Vencord local CSS theme
    -> Freesm/Qt applications through qt5ct/qt6ct
```

A geração usa arquivos temporários e `mv` atômico. O modo inicial é dark: dconf `prefer-dark`, GTK `adw-gtk3-dark`, Qt via qt6ct e ZenNotes `theme_mode = "dark"`; o contrato do tema ZenNotes declara `modes = "both"` e recebe tokens light/dark no mesmo CSS. Cada consumidor recebe somente o formato que seu ecossistema entende. Xournal++ mantém `settings.xml` e `toolbar.ini` editáveis no owner nativo `~/.config/xournalpp`; o adapter atualiza idempotentemente apenas `colorPalette` e a paleta `.gpl` é regenerada pelo Matugen. Vesktop/Vencord recebe um tema CSS local em `themes/` e seu nome é mantido em `settings.json.enabledThemes`; o plugin `ClientTheme` não é usado como substituto para uma paleta multi-token.

### Consumidores

| Consumer | Contrato |
|---|---|
| Noctalia | `~/.config/noctalia/palettes/Serpantinum.json`, generated from Matugen roles |
| QuickShell | `SERPANTINUM_THEME_JSON` points to `qs_colors.json` when the Serpantinum backend is selected |
| GTK/Nautilus | `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, dconf e Flatpak read access |
| Qt | qt5ct/qt6ct palette e QSS em paths do usuário |
| WezTerm | Lua `dofile` de `~/.config/wezterm/matugen-colors.lua` e hook de reload |
| Neovim | `~/.config/nvim/matugen_colors.lua`, carregado opcionalmente por NixVim |
| Firefox/Zen | `chrome/userChrome.css`, backup e user.js com preferência habilitada |
| ZenNotes | `themes/serpantinum/{manifest.json,theme.css}` e `theme_id = "custom-serpantinum"` |
| Xournal++ | `palettes/serpantinum.gpl` em formato GIMP e `settings.xml` com `colorPalette` |
| Vesktop/Vencord | `themes/serpantinum.theme.css` e `settings/settings.json.enabledThemes` |
| Freesm Launcher | Flatpak override Qt6ct + QSS/palette; o launcher continua usando seus próprios ícones/recursos |

Firefox e Zen dependem de CSS interno não estável; o adapter deve ser pequeno, versionável e sempre ter backup. ZenNotes documenta `theme_id` para o id resolvido `custom-<slug>`, por isso `custom-serpantinum` é usado explicitamente.

## 7. Wallpapers e automação

`home/livara/sync.nix` sincroniza o catálogo em `~/Wallpapers`. O clone inicial ocorre em diretório temporário e é movido atomicamente. Atualizações usam `fetch --prune` e `merge --ff-only`; erro de rede mantém o checkout atual. O timer não executa scripts do repositório.

O serviço de login espera o daemon `awww`, procura imagens recursivamente em `WALLPAPER_DIR`, escolhe uma imagem válida, aplica-a e executa Matugen. A seleção falha de forma não fatal quando o catálogo está vazio ou a sessão ainda não possui monitor disponível.

## 8. Input 60%

`Ctrl+H/J/K/L` não é um binding de Hyprland. O módulo `services.keyd` usa a camada:

```ini
[ids]
*

[control:C]
h = left
j = down
k = up
l = right
```

Isso produz eventos de seta antes de o compositor e o aplicativo consumirem o input. Ctrl continua normal para outras teclas. A regra deve ser validada em cada host com `keyd monitor`, `keyd check` e logs systemd; se um segundo teclado exigir comportamento diferente, os IDs devem ser estreitados por opção.

## 9. NixVim e Xournal++

`vim-conf` continua separado. Ele publica o módulo NixVim, plugins, linguagens e keymaps. A paleta Matugen é opcional em runtime: a avaliação do flake não depende de Matugen ou QuickShell, e o editor mantém fallback quando o arquivo de cores não existe.

`xournal-conf` é tratado como dados de aplicação. O perfil editável ativo é `~/.config/xournalpp`; a ativação migra uma cópia anterior de `~/.config/nixos/xournalpp` somente quando o path nativo ainda não possui o arquivo. Uma paleta desktop não deve reescrever `settings.xml` ou `toolbar.ini` em cada activation, exceto a propriedade dinâmica `colorPalette` controlada pelo adapter.

## 10. Segurança e estado

Arquivos mutáveis ficam em `$XDG_STATE_HOME/serpantinum`, `$XDG_CONFIG_HOME` ou diretórios de perfil definidos pela aplicação. CSS de browser recebe backup antes de ser substituído. Nenhum script remove um arquivo regular sem cópia, e nenhum output derivado deve ser um link imutável para `/nix/store`.

A ativação não faz `git pull`, baixa assets ou exige rede. Serviços de sincronização são independentes. Scripts usam paths configuráveis, `set -euo pipefail`, falhas toleráveis onde apropriado e não executam instruções encontradas em conteúdo externo. O weather usa Open-Meteo por coordenadas fixas de Jardim João XXIII (`-23.60285,-46.79271`) com cache e fallback offline. O launcher usa `DesktopEntries.applications` e `DesktopEntry.command`; o antigo guide foi removido do registro ativo, e a ação da barra/`Super+H` abre `~/.config/nixos` com Neo-tree.

## 11. Validação

A sequência de validação é progressiva:

```bash
git diff --check
find scripts -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
nix flake check --no-build --no-update-lock-file --show-trace
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
nix build .#nixosConfigurations.latitude.config.system.build.toplevel
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
```

Também é obrigatório procurar resíduos no caminho ativo:

```bash
git grep -n -I -E 'legacy-shell|deprecated-shell|old-shell' -- ':!docs/archive/**' ':!ARCHITECTURE.md'
```

A avaliação local usa o backend Nix disponível no sandbox; os checks de build e a troca final ainda devem ser executados no NixOS real antes de `nixos-rebuild test` e `switch`.

## 12. Referências

[1]: https://nix-community.github.io/home-manager/installation/nixos.html "Home Manager — NixOS module"
[2]: https://wiki.nixos.org/wiki/Hyprland "NixOS Wiki — Hyprland"
[3]: https://wiki.nixos.org/wiki/UWSM "NixOS Wiki — UWSM"
[4]: https://github.com/Joaoferraz-byte/shell-conf "shell-conf"
[6]: https://github.com/InioX/matugen "Matugen"
[7]: https://github.com/rvaiya/keyd "keyd"
[8]: https://raw.githubusercontent.com/rvaiya/keyd/master/docs/keyd.scdoc "keyd manual"
[9]: https://github.com/nix-community/nixvim "NixVim"
[10]: https://xournalpp.github.io/guide/file-locations/ "Xournal++ file locations"
[11]: https://docs.zen-browser.app/guides/live-editing "Zen Browser live editing"
[12]: https://zennotes.org/docs "ZenNotes documentation"
