# Arquitetura do Sistema — nix-conf

> Documento de mapeamento vivo da configuração NixOS declarativa para o host `limine`.
> Última atualização: 2026-07-29

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
│       ├── home.nix                   # Configuração Home Manager do usuário livara
│       └── nvim-config/               # Config Lua legada (substituída pelo lua-conf externo)
│           ├── init.lua
│           └── lua/
│               ├── core/              # Opções e keymaps base
│               ├── dap/               # Debug Adapter Protocol
│               ├── lsp/               # Language Server Protocol
│               ├── plugins/           # Plugins gerais
│               └── ui/                # Interface (dashboard)
└── modules/
    ├── parts.nix                      # Define sistemas suportados (x86_64-linux, aarch64-linux)
    ├── features/                      # Módulos de funcionalidades isoladas
    │   ├── audiorelay.nix             # AudioRelay (Flatpak) + PipeWire virtual nodes
    │   ├── desktop-portals.nix        # XDG portals, Polkit, GNOME Keyring
    │   ├── flatpak.nix                # Gerenciamento declarativo de Flatpaks via nix-flatpak
    │   ├── greeter.nix                # Greeter de login (greetd + regreet)
    │   ├── keyd.nix                   # Remapeamento de teclado (leftmeta → overload)
    │   ├── neovim-wrapped.nix         # Neovim via nix-wrapper-modules + lua-conf externo
    │   ├── niri.nix                   # Compositor Wayland Niri (configuração completa)
    │   ├── noctalia.json              # Configuração da barra Noctalia (JSON)
    │   ├── noctalia.nix               # Wrapper Noctalia via nix-wrapper-modules
    │   ├── nvidia.nix                 # Driver NVIDIA legacy_580 + hardware.graphics
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
└── lua-conf (flake = false)           → repositório externo de configuração Lua do Neovim
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
| `neovimWrapped` | Neovim com plugins Nix + config Lua do lua-conf |

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
        │     └── nixosModules.neovimWrapped
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

---

## Configuração do Editor (Neovim)

O Neovim é gerenciado como um **pacote de sistema** via `neovim-wrapped.nix`, usando `nix-wrapper-modules`. A configuração Lua reside no repositório externo `lua-conf` (input do flake).

### Plugins declarados (nix-conf)
`nvim-lspconfig`, `nvim-treesitter`, `nvim-cmp`, `cmp-nvim-lsp`, `cmp-buffer`, `cmp-path`, `luasnip`, `github-nvim-theme`, `nvim-java`, `nvim-tree-lua`, `nvim-web-devicons`, `lualine-nvim`, `telescope-nvim`, `plenary-nvim`, `vim-fugitive`, `gitsigns-nvim`, `which-key-nvim`, `bufferline-nvim`, `snacks-nvim`, `nvim-dap`, `nvim-dap-ui`, `nvim-nio`

### Runtime packages (nix-conf)
`gcc`, `clang-tools`, `cmake`, `gnumake`, `maven`, `gradle`, `jdk21`, `jdt-language-server`, `spring-boot-cli`, `kotlin`, `kotlin-language-server`, `pyright`, `vscode-langservers-extracted`, `typescript-language-server`, `angular-language-server`, `tailwindcss-language-server`, `prettier`, `ripgrep`, `fd`, `unzip`, `gnutar`, `python3`, `python3Packages.manim`

### Estrutura lua-conf
```
lua-conf/
├── init.lua                    # Ponto de entrada; carrega todos os módulos
└── lua/
    ├── custom_core/
    │   ├── options.lua         # Opções do Neovim (números de linha, tabs, etc.)
    │   └── keymaps.lua         # Keymaps globais
    ├── custom_dap/
    │   └── init.lua            # Configuração do DAP (debug)
    ├── custom_lsp/
    │   └── init.lua            # LSP: jdtls, clangd, pyright, angularls, etc.
    ├── custom_plugins/
    │   └── init.lua            # Treesitter, nvim-cmp, nvim-tree, lualine, etc.
    └── custom_ui/
        └── init.lua            # Dashboard (snacks.nvim)
```

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

1. **`nvim-config/` legado em `home/livara/`**: A pasta `home/livara/nvim-config/` contém uma configuração Lua antiga que não é mais usada pelo sistema (o wrapper aponta para `lua-conf`). Deve ser removida para evitar confusão.
2. **Pacotes duplicados no sistema**: `jdk21` e `jdt-language-server` aparecem tanto em `configuration.nix` quanto nos `runtimePkgs` do `neovim-wrapped.nix`. Devem ser consolidados em um módulo de pacotes dedicado.
3. **Ausência de CI/CD**: Sem automação para validar o flake via GitHub Actions.
4. **Pino de `nixpkgs-stable`**: Ainda necessário para o Niri; deve ser removido quando o upstream estabilizar.
