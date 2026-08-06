# nix-conf — NixOS Configuration

Sistema NixOS declarativo com Niri, DankMaterialShell (DMS) e ambiente de desenvolvimento Java/C++. Gerenciado por flake-parts com import-tree para módulos.

## Estrutura

```
nix-conf/
├── flake.nix                  # Inputs, outputs, perSystem
├── flake.lock                 # Pino de dependências
├── ARCHITECTURE.md            # Este arquivo
├── CHANGELOG.md               # Histórico de mudanças
├── Icons/                     # Avatar e assets do greeter
├── home/livara/home.nix       # Home Manager do usuário
├── modules/
│   ├── README.md              # Convenções de módulos
│   ├── parts.nix              # Sistemas suportados e composição
│   ├── features/              # Módulos de funcionalidades
│   ├── hosts/                 # Configurações por máquina
│   └── packages/              # Pacotes Nix e Flatpak
└── themes/clockwork/          # Tema SDDM
```

## Grafo de Inputs

```
flake.nix
├── nixpkgs (nixos-unstable)
├── flake-parts
├── import-tree
├── nix-flatpak
├── home-manager → follows nixpkgs
├── nixvim
├── vim-conf (flake)
│   └── nixvim (independente)
├── shell-conf (flake) → follows nixpkgs
│   ├── dms (DankMaterialShell)
│   └── niri (niri-flake)
└── dms-plugin-registry → follows nixpkgs
```

## Módulos NixOS

| Módulo | Responsabilidade |
|---|---|
| `corePackages` | Pacotes de sistema (git, gh, ferramentas Java, etc.) |
| `greeter` | SDDM + Clockwork theme + Bibata cursor |
| `desktop-portals` | XDG portals, Polkit, GNOME Keyring |
| `flatpak` | Flatpaks declarativos via nix-flatpak |
| `audiorelay` | AudioRelay Flatpak + PipeWire virtual nodes |
| `keyd` | Remapeamento `leftmeta` → `overload(meta, menu)` |
| `nvidia` | Driver NVIDIA (my-machine only) |
| `system-hardening` | Firewall, sudo, GC automático, zram |
| `myMachineHardware` | Hardware, filesystems btrfs, microcode AMD |
| `latitudeHardware` | Hardware, filesystems btrfs, microcode Intel |
| `shell-conf` | DankMaterialShell + Niri (via inputs.shell-conf) |

## Shell (shell-conf)

O `shell-conf` é um flake separado que empacota DankMaterialShell e Niri com integração:

| Input | Responsabilidade |
|---|---|
| `dms.homeModules.dank-material-shell` | Configurações DMS (temas, widgets, plugins) |
| `dms.homeModules.niri` | Integração niri + DMS (keybinds preset, spawn automático) |

Internamente, o `dms.homeModules.niri` já importa `niri-flake` home-manager module, evitando conflitos de opção `programs.niri`.

## Editor (vim-conf)

O `vim-conf` é um flake separado que empacota a configuração NixVim com tema DMS dinâmico:

| Input | Responsabilidade |
|---|---|
| `nixvim.legacyPackages` | Construção do pacote Neovim |
| Tema DMS | Cores lidas de matugen em `~/.config/DankMaterialShell/dms.css` |

## Hosts

| Host | Descrição | Kernel | GPU |
|---|---|---|---|
| `myMachine` | Desktop AMD + NVIDIA | zen | NVIDIA |
| `latitude` | Dell Latitude 5410 (Intel) | latest | Intel iGPU |

Ambos compartilham a mesma configuração de shell (shell-conf) e home-manager (home.nix).
