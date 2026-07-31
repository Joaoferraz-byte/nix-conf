# nix-conf — NixOS Configuration

> Sistema NixOS declarativo com Hyprland, Ambxst-X shell, e ambiente de desenvolvimento Java/C++.
> Gerenciado por flake-parts com import-tree para módulos.

---

## Visão Geral

Este repositório contém a configuração completa de um sistema NixOS baseado em **flakes**, para um desktop de alto desempenho com GPU NVIDIA, compositor Wayland **Hyprland**, e um ambiente de desenvolvimento focado em **Java Spring Boot** e **C/C++**.

A arquitetura segue os princípios de:
- **Declaratividade total**: todo o estado do sistema é descrito em código Nix.
- **Modularidade**: cada funcionalidade é isolada em seu próprio módulo `.nix`.
- **Reprodutibilidade**: `flake.lock` pinna todas as dependências.

---

## Estrutura de Diretórios

```
nix-conf/
├── flake.nix                      # Flake principal: inputs, outputs, perSystem
├── flake.lock                     # Pino de dependências
├── ARCHITECTURE.md                # Documentação arquitetural (este arquivo)
├── CHANGELOG.md                   # Histórico de mudanças
├── Icons/                         # Assets de ícones (wallpaper do greeter)
├── Wallpapers/                    # Wallpapers gerenciados pelo Ambxst-X
├── home/
│   └── livara/
│       └── home.nix               # Configuração Home Manager do usuário livara
└── modules/
    ├── parts.nix                  # Lista de sistemas suportados
    ├── README.md                  # Convenções de módulos
    ├── archive/                   # Módulos arquivados (histórico)
    │   ├── default.nix            # Stub vazio
    │   ├── noctalia.json          # Configuração Noctalia antiga (JSON) [arquivado]
    │   └── noctalia.nix           # Wrapper Noctalia antigo [arquivado]
    ├── features/                  # Módulos de funcionalidades isoladas
    │   ├── audiorelay.nix         # AudioRelay (Flatpak) + PipeWire virtual nodes
    │   ├── desktop-portals.nix    # XDG portals, Polkit, GNOME Keyring
    │   ├── flatpak.nix            # Gerenciamento declarativo de Flatpaks via nix-flatpak
    │   ├── greeter.nix            # Greeter de login (SDDM + SilentSDDM)
    │   ├── keyd.nix               # Remapeamento de teclado (leftmeta → overload)
    │   ├── hyprland.nix           # Compositor Wayland Hyprland (configuração completa via UWSM)
    │   ├── ambxst.nix             # Shell Ambxst-X (Quickshell + axctl + Hyprland)
    │   ├── nvidia.nix             # Driver NVIDIA legacy_580 + hardware.graphics
    │   ├── shell.nix              # Módulo quickshell anterior [removido - sem uso]
    │   └── system-hardening.nix   # Firewall, sudo, GC automático, zram
    └── hosts/
        ├── my-machine/
        │   ├── default.nix        # Define nixosConfigurations.myMachine + Home Manager
        │   ├── configuration.nix  # Importa todos os módulos; pacotes de sistema; locale
        │   └── hardware.nix       # UUIDs de disco, módulos de kernel, microcode AMD
        └── dell-latitude-5410/
            ├── default.nix        # Define nixosConfigurations.dell-latitude-5410
            ├── configuration.nix  # Configuração específica do laptop Dell
            └── hardware.nix       # Hardware específico do laptop Dell
```

---

## Grafo de Dependências de Inputs

```
flake.nix
├── nixpkgs (nixos-unstable)           → fonte principal de pacotes
├── flake-parts                        → estrutura modular do flake
├── import-tree                        → auto-importação recursiva de ./modules
├── nix-flatpak                        → gerenciamento declarativo de Flatpaks
├── home-manager (master)              → configuração do usuário livara
│   └── follows nixpkgs
├── vim-conf (flake)                   → repositório externo de configuração NixVim declarativa
├── shell-conf (flake)                 → Ambxst-X shell (Quickshell + axctl + Hyprland)
│   └── follows nixpkgs
└── silentSDDM (flake)                 → Tema SilentSDDM e perfil via AccountsService
    └── follows nixpkgs
```

---

## Módulos NixOS Exportados

Todos os módulos são exportados como `flake.nixosModules.<nome>` e importados em `configuration.nix`:

| Módulo | Responsabilidade |
| :--- | :--- |
| `myMachineHardware` | Hardware, filesystems btrfs, microcode AMD |
| `myMachineConfiguration` | Módulo raiz do host; importa todos os outros |
| `hyprland` | Compositor Wayland Hyprland, UWSM, keybindings, regras de janela |
| `nvidia` | Driver proprietário NVIDIA legacy_580 |
| `greeter` | Login com SDDM + SilentSDDM (Wayland) e avatar por AccountsService |
| `desktop-portals` | XDG portals (Hyprland + GTK), Polkit, GNOME Keyring |
| `flatpak` | Flatpaks declarativos via nix-flatpak |
| `audiorelay` | AudioRelay Flatpak + nós virtuais PipeWire + firewall |
| `keyd` | Remapeamento `leftmeta` → `overload(meta, menu)` |
| `ambxst` | Shell Quickshell (Ambxst-X) integrado ao Hyprland via axctl |
| `nixvim` (via Home Manager) | Neovim declarativo via vim-conf flake + NixVim module |
| `ambxst` (via Home Manager) | Configurações JSON do Ambxst-X + settings customizados |
| `hyprland` (via Home Manager) | Configuração do usuário do Hyprland (keybinds, monitor, window rules) |

---

## Fluxo de Avaliação do Sistema

```
nixos-rebuild switch --flake .#myMachine
        │
        ▼
flake.nix → import-tree ./modules
        │
        ▼
modules/hosts/my-machine/default.nix
  → nixosConfigurations.myMachine
        │
        ├── nixosModules.myMachineConfiguration (configuration.nix)
        │     ├── nixosModules.myMachineHardware
        │     ├── nixosModules.hyprland
        │     ├── nixosModules.nvidia
        │     ├── nixosModules.greeter
        │     ├── nixosModules.desktop-portals
        │     ├── nixosModules.flatpak
        │     ├── nixosModules.audiorelay
        │     ├── nixosModules.keyd
        │     ├── nixosModules.ambxst
        │     └── home-manager.users.livara → home/livara/home.nix
        │
        └── home-manager.users.livara → home/livara/home.nix
```

---

## Configuração do Usuário (Home Manager)

O arquivo `home/livara/home.nix` gerencia:
- **Shell**: ZSH com oh-my-zsh, autosuggestions, syntax highlighting, fzf
- **Terminal**: Alacritty com tema GitHub Dark e JetBrainsMono Nerd Font
- **MIME types**: Associações de arquivos (PDF → Okular, código → Neovim)
- **XDG User Dirs**: Diretórios padrão criados declarativamente
- **Variáveis de sessão**: `PROJECTS_DIR`
- **Tema de ícones**: Papirus-Dark (GTK + dconf, lido pelo wrapper do Ambxst-X)
- **Tema GTK**: adw-gtk3-dark
- **Avatar**: `~/.face.icon` proveniente do mesmo ativo versionado em `Icons/` usado pelo SilentSDDM antes do login.

---

## Configuração do Editor (Neovim)

O Neovim é gerenciado via **NixVim** como módulo do Home Manager, com a configuração declarativa no repositório externo `vim-conf`.

### Arquitetura NixVim
- `programs.nixvim.enable = true` no `home.nix` do usuário
- `programs.nixvim.imports = [ inputs.vim-conf.lib.nixvimModule ]` — carrega a configuração do flake vim-conf
- O módulo oficial do NixVim (`inputs.nixvim.homeModules.nixvim`) é registrado em `home-manager.sharedModules`
- O binário executável é exposto via `inputs.vim-conf.packages.<system>.default`

---

## Dívidas Técnicas Identificadas

1. **Sincronização de Wallpapers**: A pasta `Wallpapers/` deve ser sincronizada com o gerenciador de wallpapers do Ambxst-X.
2. **Pacotes duplicados no sistema**: `jdk21` e `jdt-language-server` devem ser consolidados em um módulo de pacotes dedicado.
3. **Ausência de CI/CD**: Sem automação para validar o flake via GitHub Actions.
4. **Widgets de Desktop**: Migrar os widgets legados do Noctalia para o sistema nativo do Ambxst-X.
5. **Módulos legados**: `shell.nix` pode ser removido com segurança (stub vazio). `noctalia.nix` e `noctalia.json` estão neutralizados.
