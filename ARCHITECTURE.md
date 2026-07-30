# Arquitetura do Sistema — nix-conf

> Documento de mapeamento vivo da configuração NixOS declarativa para o host `limine`.
> Última atualização: 2026-07-30

---

## Visão Geral

Este repositório contém a configuração completa de um sistema NixOS baseado em **flakes**, para um desktop de alto desempenho com GPU NVIDIA, compositor Wayland **Niri**, e um ambiente de desenvolvimento focado em **Java Spring Boot** e **C/C++**.

A arquitetura segue os princípios de:
- **Declaratividade total**: todo o estado do sistema é descrito em código Nix.
- **Modularidade**: cada funcionalidade é isolada em seu próprio módulo `.nix`.
- **Reprodutibilidade**: o `flake.lock` garante builds determinísticos.
- **Separação de responsabilidades**: configuração de sistema (NixOS) vs. configuração de usuário (Home Manager) vs. configuração do editor (lua-conf).

---

## Estrutura de Diretórios

```
nix-conf/
├── flake.nix                          # Ponto de entrada do flake; define inputs e outputs
├── flake.lock                         # Lock file para reprodutibilidade
├── ARCHITECTURE.md                    # Este documento
├── ARCHITECTURE_REVIEW_REPORT.md      # Relatório de revisão arquitetural anterior
├── CHANGELOG.md                       # Histórico de mudanças
├── Wallpapers/                        # Papéis de parede (assets estáticos)
├── home/
│   └── livara/
│       └── home.nix                   # Configuração Home Manager do usuário livara
└── modules/
    ├── parts.nix                      # Define sistemas suportados (x86_64-linux, aarch64-linux)
    ├── features/                      # Módulos de funcionalidades isoladas
    │   ├── audiorelay.nix             # AudioRelay (Flatpak) + PipeWire virtual nodes
    │   ├── desktop-portals.nix        # XDG portals, Polkit, GNOME Keyring
    │   ├── flatpak.nix                # Gerenciamento declarativo de Flatpaks via nix-flatpak
    │   ├── greeter.nix                # Greeter de login (greetd + regreet)
    │   ├── keyd.nix                   # Remapeamento de teclado (leftmeta → overload)
    │   ├── niri.nix                   # Compositor Wayland Niri (configuração completa)
    │   ├── ambxst.nix               # Shell Ambxst (Quickshell + axctl + Niri)
    │   ├── noctalia.json              # Configuração da barra Noctalia (JSON) [legado]
    │   ├── noctalia.nix               # Wrapper Noctalia via nix-wrapper-modules [legado]
    │   ├── nvidia.nix                 # Driver NVIDIA legacy_580 + hardware.graphics
    │   ├── shell.nix                  # Módulo quickshell anterior [substituído por ambxst.nix]
    │   └── system-hardening.nix      # Firewall, sudo, GC automático, zram
    └── hosts/
        └── my-machine/
            ├── default.nix            # Define nixosConfigurations.myMachine + Home Manager
            ├── configuration.nix      # Importa todos os módulos; pacotes de sistema; locale
            └── hardware.nix           # UUIDs de disco, módulos de kernel, microcode AMD
```

---

## Grafo de Dependências de Inputs

```
flake.nix
├── nixpkgs (nixos-unstable)           → fonte principal de pacotes
├── nixpkgs-stable (pino fixo)         → segurança para builds instáveis do niri
├── flake-parts                        → estrutura modular do flake
├── import-tree                        → auto-importação recursiva de ./modules
├── wrapper-modules                    → wrappers para Neovim e Noctalia
├── nix-flatpak                        → gerenciamento declarativo de Flatpaks
├── home-manager (master)              → configuração do usuário livara
│   └── follows nixpkgs
├── vim-conf (flake)                   → repositório externo de configuração NixVim declarativa
└── shell-conf (flake)                 → Ambxst shell (Quickshell + axctl + Niri)
    └── follows nixpkgs
```

---

## Módulos NixOS Exportados

Todos os módulos são exportados como `flake.nixosModules.<nome>` e importados em `configuration.nix`:

| Módulo | Responsabilidade |
| :--- | :--- |
| `myMachineHardware` | Hardware, filesystems btrfs, microcode AMD |
| `myMachineConfiguration` | Módulo raiz do host; importa todos os outros |
| `niri` | Compositor Wayland, keybindings, regras de janela |
| `nvidia` | Driver proprietário NVIDIA legacy_580 |
| `greeter` | Login com greetd + regreet (tema adw-gtk3-dark) |
| `desktop-portals` | XDG portals (gnome+gtk), Polkit, GNOME Keyring |
| `flatpak` | Flatpaks declarativos via nix-flatpak |
| `audiorelay` | AudioRelay Flatpak + nós virtuais PipeWire + firewall |
| `keyd` | Remapeamento `leftmeta` → `overload(meta, menu)` |
| `ambxst` | Shell Quickshell (Ambxst) com axctl para Niri, fontes e JSONs de config |
| `nixvim` (via Home Manager) | Neovim declarativo via vim-conf flake + NixVim module |
| `ambxst` (via Home Manager) | Configurações JSON do Ambxst + keybinds declarativos |

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
        │     ├── nixosModules.niri
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
- **Tema de ícones**: Papirus-Dark (GTK + dconf, lido pelo wrapper do Ambxst)
- **Tema GTK**: adw-gtk3-dark

---

## Configuração do Editor (Neovim)

O Neovim é gerenciado via **NixVim** como módulo do Home Manager, com a configuração declarativa no repositório externo `vim-conf`.

### Arquitetura NixVim
- `programs.nixvim.enable = true` no `home.nix` do usuário
- `programs.nixvim.imports = [ inputs.vim-conf.lib.nixvimModule ]` — carrega a configuração do flake vim-conf
- O módulo oficial do NixVim (`inputs.nixvim.homeModules.nixvim`) é registrado em `home-manager.sharedModules`
- O binário executável é exposto via `inputs.vim-conf.packages.<system>.default`

### Plugins declarados (vim-conf)
Consulte `vim-conf/config/plugins/` para a lista completa de plugins configurados declarativamente.

### Linguagens suportadas
Consulte `vim-conf/config/languages/` para as configurações de Java, Web, C/C++, embarcados e programação competitiva.

---

## Pacotes de Sistema (configuration.nix)

Pacotes instalados globalmente em `environment.systemPackages`:

| Pacote | Categoria |
| :--- | :--- |
| `git`, `gh` | Controle de versão |
| `nautilus` | Gerenciador de arquivos |
| `brave` | Navegador web |
| `vesktop` | Cliente Discord |
| `kdePackages.okular` | Leitor de PDF |
| `foliate` | Leitor de e-books |
| `obsidian` | Notas |
| `hydralauncher`, `heroic` | Launchers de jogos |
| `jdk21`, `jdk8` | Java Development Kit |
| `jdt-language-server` | LSP para Java |
| `spring-boot-cli` | CLI Spring Boot |

---

## Dívidas Técnicas Identificadas

1. **Desktop entry do NixVim**: O desktop entry agora referencia o pacote do flake vim-conf diretamente, garantindo consistência com o módulo HM.
2. **Pacotes duplicados no sistema**: `jdk21` e `jdt-language-server` aparecem tanto em `configuration.nix` quanto em `vim-conf/config/plugins/core.nix`. Devem ser consolidados em um módulo de pacotes dedicado.
3. **Ausência de CI/CD**: Sem automação para validar o flake via GitHub Actions.
4. **Pino de `nixpkgs-stable`**: Ainda necessário para o Niri; deve ser removido quando o upstream estabilizar.
5. **Módulos legados**: `shell.nix` e `noctalia.nix` podem ser removidos após confirmação de que o Ambxst está funcionando corretamente.
