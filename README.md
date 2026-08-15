# nix-conf

Configuração declarativa de NixOS para dois hosts, com uma base compartilhada de Hyprland/UWSM, Home Manager, NixVim, Serpantinum e serviços de desktop. O objetivo é manter a experiência comum entre notebook e computador, deixando divergências limitadas a hardware e pequenas capacidades de interface.

## Hosts

| Host | Perfil | Diferenças intencionais |
|---|---|---|
| `latitude` | notebook | energia, Intel, ext4 e widgets de Wi-Fi/Bluetooth prioritários |
| `myMachine` | desktop | GPU/monitores, Btrfs/virtualização e Bluetooth opcional na interface |

A composição está em `modules/hosts/common-desktop.nix`. Ela injeta o mesmo módulo Home Manager do `shell-conf`, o NixVim e o perfil do usuário; hardware e política específica continuam nos módulos de cada host.

## Shell

O shell visual ativo é o Serpantinum, adaptado e publicado pelo repositório [shell-conf](https://github.com/Joaoferraz-byte/shell-conf). A árvore local contém a cópia QuickShell/Hyprland revisada e expõe `homeManagerModules.default`; o flake local é um adaptador NixOS/Home Manager, não um flake fornecido pela fonte original.

NixOS habilita Hyprland com UWSM e fornece dependências system-side; Home Manager instala o shell e seus serviços de usuário; `serpantinum-shell` inicia QuickShell; `serpantinum-wallpaper-daemon` gerencia `awww`; e `serpantinum-wallpaper-random-on-login` seleciona a imagem inicial e executa Matugen.

## Tema adaptativo

O repositório de wallpapers é sincronizado para `~/Wallpapers`, caminho canônico exposto como `WALLPAPER_DIR`. O weather usa Open-Meteo por coordenadas de Jardim João XXIII, com cache e fallback offline. O launcher usa a API nativa `DesktopEntries` do QuickShell; `Super+H` e o ícone correspondente da barra abrem `~/.config/nixos` com Neo-tree no Neovim. Uma troca de wallpaper gera uma paleta Matugen e arquivos mutáveis para QuickShell, Hyprland, GTK3/GTK4, Qt, WezTerm, Neovim, Firefox/Zen, ZenNotes, Xournal++ e Vesktop/Vencord. O modo inicial é dark e o sincronizador preserva backups de CSS de perfil antes de substituir arquivos.

Firefox e Zen usam `chrome/userChrome.css` e `toolkit.legacyUserProfileCustomizations.stylesheets`. ZenNotes usa o tema customizado `custom-serpantinum`, com `theme.css`, `manifest.json`, `theme_family = "custom"`, `theme_id = "custom-serpantinum"` e `theme_mode = "dark"`.

## Atalhos, locale e teclado 60%

A tradução global de `Ctrl+H/J/K/L` é feita em `modules/features/keyd.nix`, não no compositor. A camada keyd `[control:C]` emite `left`, `down`, `up` e `right`, de modo que os aplicativos recebam eventos de seta genuínos antes de interpretar H/J/K/L. O wildcard cobre os dois hosts; IDs específicos podem ser configurados depois de validar `keyd monitor` em cada teclado.

## Wallpaper e sincronização

`home/livara/sync.nix` mantém timers independentes para Wallpapers e Vault. O clone inicial é atômico; atualizações usam fetch/fast-forward e falhas de rede mantêm o último checkout válido. O wallpaper service não depende de um `git pull` bem-sucedido para iniciar a sessão.

## Repositórios relacionados

`vim-conf` continua sendo o owner de NixVim, plugins, linguagens e keymaps. `xournal-conf` continua sendo o owner dos arquivos editáveis de Xournal++, como `settings.xml`, `toolbar.ini`, template LaTeX e paletas. `Wallpapers` é tratado como catálogo de assets, sem lógica de sessão.

## Instalação e validação

A instalação normal é realizada por `install.sh`, que deve ser executado como usuário comum. A configuração valida hardware, árvore Git, `nix flake check --no-build --no-update-lock-file` e avaliação do host antes de chamar `nixos-rebuild`.

```bash
./install.sh
```

Para validar:

```bash
git diff --check
nix flake check --no-build --no-update-lock-file --show-trace
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
nix build .#nixosConfigurations.latitude.config.system.build.toplevel
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
```

Depois da ativação, confira:

```bash
systemctl --user status serpantinum-shell.service
systemctl --user status serpantinum-wallpaper-daemon.service
systemctl --user status serpantinum-wallpaper-random-on-login.service
keyd monitor
```

A auditoria usa Nix em modo local para avaliação; builds completos e `nixos-rebuild switch` devem ainda ser executados no NixOS real, com os drivers e hardware de cada host.
