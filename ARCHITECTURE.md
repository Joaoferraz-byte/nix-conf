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

O flake do `nix-conf` importa `shell-conf` e não contém inputs operacionais de DMS, Niri ou end-4. O repositório `shell-conf` mantém uma cópia revisada do source Serpantinum necessário porque o upstream não oferece flake NixOS estável.

## 4. Hyprland, UWSM e Serpantinum

`modules/features/hyprland.nix` habilita `programs.hyprland.enable = true`, `withUWSM = true` e o portal Hyprland. Home Manager não inicia um segundo lifecycle do compositor. `home/livara/session.nix` owns apenas `hypridle`, diretório de screenshots e limpeza segura de arquivos Lua legados.

O módulo Home Manager do `shell-conf` instala os assets estáticos em `~/.config/hypr`, inicia `serpantinum-shell.service` com QuickShell e inicia `serpantinum-wallpaper-daemon.service` com `awww`. O autostart upstream não inicia novamente esses processos.

| Concern | Owner |
|---|---|
| Login e compositor | NixOS Hyprland + UWSM |
| Idle/lock policy | `home/livara/session.nix` + hypridle |
| Shell surface e widgets | `shell-conf` / Serpantinum |
| Wallpaper daemon | `shell-conf` / user systemd |
| Wallpaper catalog | `Wallpapers` + `sync.nix` |
| Privileged input remapping | `modules/features/keyd.nix` |
| Runtime colors | `shell-conf` / Matugen |

## 5. Serpantinum como adaptador NixOS

O upstream Serpantinum é um source tree imperativo com paths pessoais, `configuration.nix`, `home.nix`, scripts e referências a `/etc/nixos`. O `shell-conf` não executa o instalador upstream. Ele copia apenas a árvore revisada de sessões Hyprland/QuickShell, templates Matugen e configuração Kitty, e fornece um flake próprio.

O módulo Home Manager declara opções tipadas:

```text
programs.serpantinum.enable
programs.serpantinum.wallpaperDirectory
programs.serpantinum.hostProfile
programs.serpantinum.networkWidgets
programs.serpantinum.bluetoothWidgets
```

O shell recebe essas opções por `SERPANTINUM_*`. O QML detecta hardware de rede por capacidade e não pelo hostname; o perfil apenas controla pequenas decisões de apresentação, especialmente Wi-Fi/Bluetooth no notebook.

## 6. Tema adaptativo

Matugen é executado uma vez por troca de wallpaper e gera outputs mutáveis. Templates estáticos vivem no Nix store; os arquivos resultantes não são links para o store. O fluxo é:

```text
image under WALLPAPER_DIR
  -> matugen image
    -> QuickShell JSON
    -> Hyprland colors.conf
    -> GTK3/GTK4 CSS
    -> Qt palettes and QSS
    -> Kitty/WezTerm colors
    -> Neovim Lua palette
    -> Firefox/Zen userChrome.css
    -> ZenNotes custom theme
```

A geração usa arquivos temporários e `mv` atômico. O modo inicial é dark: dconf `prefer-dark`, GTK `adw-gtk3-dark`, Qt via qt6ct e ZenNotes `theme_mode = "dark"`. A pipeline não tenta transformar Xournal++ em estado derivado; `settings.xml` e `toolbar.ini` permanecem editáveis.

### Consumidores

| Consumer | Contrato |
|---|---|
| QuickShell | `SERPANTINUM_THEME_JSON` aponta para `qs_colors.json` |
| GTK/Nautilus | `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, dconf e Flatpak read access |
| Qt | qt5ct/qt6ct palette e QSS em paths do usuário |
| Kitty | `~/.config/kitty/matugen-colors.conf` incluído pelo `kitty.conf` |
| WezTerm | Lua `dofile` de `~/.config/wezterm/matugen-colors.lua` |
| Neovim | `~/.config/nvim/matugen_colors.lua`, carregado opcionalmente por NixVim |
| Firefox/Zen | `chrome/userChrome.css`, backup e user.js com preferência habilitada |
| ZenNotes | `themes/serpantinum/{manifest.json,theme.css}` e `theme_id = "custom-serpantinum"` |

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

`xournal-conf` é tratado como dados de aplicação. O staging local é semeado apenas quando ausente; links out-of-store preservam as edições da GUI. Uma paleta desktop não deve reescrever `settings.xml` ou `toolbar.ini` em cada activation.

## 10. Segurança e estado

Arquivos mutáveis ficam em `$XDG_STATE_HOME/serpantinum`, `$XDG_CONFIG_HOME` ou diretórios de perfil definidos pela aplicação. CSS de browser recebe backup antes de ser substituído. Nenhum script remove um arquivo regular sem cópia, e nenhum output derivado deve ser um link imutável para `/nix/store`.

A ativação não faz `git pull`, baixa assets ou exige rede. Serviços de sincronização são independentes. Scripts usam paths configuráveis, `set -euo pipefail`, falhas toleráveis onde apropriado e não executam instruções encontradas em conteúdo externo.

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
git grep -n -I -E 'DMS|dms|Niri|niri|end-4|end4|illogical-impulse|DankMaterialShell|sodiboo|AvengeMedia|Caelestia|Ambxst' -- ':!docs/archive/**' ':!ARCHITECTURE.md'
```

A avaliação local usa o backend Nix disponível no sandbox; os checks de build e a troca final ainda devem ser executados no NixOS real antes de `nixos-rebuild test` e `switch`.

## 12. Referências

[1]: https://nix-community.github.io/home-manager/installation/nixos.html "Home Manager — NixOS module"
[2]: https://wiki.nixos.org/wiki/Hyprland "NixOS Wiki — Hyprland"
[3]: https://wiki.nixos.org/wiki/UWSM "NixOS Wiki — UWSM"
[4]: https://github.com/Joaoferraz-byte/shell-conf "shell-conf"
[5]: https://github.com/ilyamiro/serpantinum "Serpantinum upstream"
[6]: https://github.com/InioX/matugen "Matugen"
[7]: https://github.com/rvaiya/keyd "keyd"
[8]: https://raw.githubusercontent.com/rvaiya/keyd/master/docs/keyd.scdoc "keyd manual"
[9]: https://github.com/nix-community/nixvim "NixVim"
[10]: https://xournalpp.github.io/guide/file-locations/ "Xournal++ file locations"
[11]: https://docs.zen-browser.app/guides/live-editing "Zen Browser live editing"
[12]: https://zennotes.org/docs "ZenNotes documentation"
