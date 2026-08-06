# nix-conf

## Visão geral

Configuração NixOS declarativa baseada em flakes para desktop e laptop. Compositor Niri + DankMaterialShell (DMS) via flake `shell-conf`.

| Área | Localização | Responsabilidade |
|---|---|---|
| Flake e entradas fixadas | `flake.nix`, `flake.lock` | Define os hosts e fixa todas as dependências transitivas. |
| Hosts | `modules/hosts/` | Declara hardware, nome do host e escolhas específicas de cada máquina. |
| Funcionalidades do sistema | `modules/features/` | Encapsula desktop, portais, áudio, greeter e demais serviços. |
| Pacotes | `modules/packages/` | Declara pacotes Nix e Flatpak. |
| Shell (DMS + Niri) | `inputs.shell-conf` | DankMaterialShell + Niri via flake separado. |
| Neovim (NixVim) | `inputs.vim-conf` | IDE declarativa com tema DMS dinâmico. |

## Shell

O DankMaterialShell + Niri é fornecido pelo flake `shell-conf`:

| Input | Responsabilidade |
|---|---|
| `dms.homeModules.dank-material-shell` | Configurações DMS (temas, widgets, plugins) |
| `dms.homeModules.niri` | Integração niri + DMS (keybinds preset, spawn) |

O `dms.homeModules.niri` internamente importa `niri-flake`, evitando conflitos de opção `programs.niri`.

## Plugins DMS

Plugins declarados via `dms-plugin-registry`:

| Plugin | Descrição |
|---|---|
| `quickCapture` | Screen capture com anotação e OCR |
| `screenCapture` | Screenshot via Niri (area, fullscreen, active window) |
| `dankQuickSearch` | Busca web rápida via prefixos de engine |

## Screenshot Keybinds (via shell-conf)

| Atalho | Ação |
|---|---|
| Super+Shift+S | Screenshot de região selecionada |
| Super+S | Screenshot de tela inteira |
| Super+Ctrl+S | Screenshot da janela ativa |

## Aplicação

```bash
sudo nixos-rebuild switch --flake .#myMachine
sudo nixos-rebuild switch --flake .#latitude
```

## Atualizações

```bash
nix flake update
nix flake check
nix build --dry-run --no-link .#nixosConfigurations.myMachine.config.system.build.toplevel
```

## Referências

- [DankMaterialShell](https://danklinux.com/docs/dankmaterialshell/nixos-flake)
- [Niri-flake](https://github.com/sodiboo/niri-flake)
- [DMS Plugin Registry](https://github.com/AvengeMedia/dms-plugin-registry)
- [shell-conf](https://github.com/Joaoferraz-byte/shell-conf)
- [vim-conf](https://github.com/Joaoferraz-byte/vim-conf)
