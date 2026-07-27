# Changelog — nix-conf

## Refatoração Completa (Jul 2026)

Este documento descreve todas as mudanças realizadas na refatoração do repositório `nix-conf`, organizadas por dimensão de melhoria. Cada alteração foi embasada em documentação oficial do NixOS, Home Manager e perspectivas da comunidade.

---

## Etapa 1 — Modularidade e Estrutura

### Home Manager integrado ao flake

**Arquivo:** `flake.nix`, `modules/hosts/my-machine/default.nix`

O [Home Manager](https://nix-community.github.io/home-manager/) foi adicionado como input do flake, seguindo a abordagem recomendada pela documentação oficial de usar `home-manager.nixosModules.home-manager` dentro do `nixosSystem`. Isso permite que a configuração do usuário seja 100% declarativa e reproduzível, sem depender de `home-manager switch` manual.

```nix
# flake.nix
home-manager = {
  url = "github:nix-community/home-manager/release-24.05";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

As opções `useGlobalPkgs = true` e `useUserPackages = true` foram habilitadas conforme recomendação da documentação para evitar duplicação de instâncias do nixpkgs.

### Arquivo home/livara.nix criado

**Arquivo:** `home/livara.nix`

Toda a configuração do usuário foi centralizada em `home/livara.nix`, fora do diretório `modules/` para evitar conflito com o `import-tree`, que importa automaticamente todos os `.nix` dentro de `modules/`.

### Remoção de duplicatas no configuration.nix

`neovim` e `alacritty` foram removidos de `environment.systemPackages`, pois agora são gerenciados pelo Home Manager, eliminando duplicação.

---

## Etapa 2 — Estabilidade e Segurança

### Migração para nixpkgs stable (24.05)

**Arquivo:** `flake.nix`

O canal foi alterado de `nixos-unstable` para `nixos-24.05`, seguindo a recomendação da [documentação oficial do NixOS](https://nixos.org/manual/nixos/stable/) para ambientes de produção que priorizam estabilidade. O `home-manager` foi fixado na versão correspondente `release-24.05` com `inputs.nixpkgs.follows = "nixpkgs"` para garantir consistência.

### stateVersion atualizado

**Arquivo:** `modules/hosts/my-machine/configuration.nix`

O `system.stateVersion` foi corrigido de `"26.05"` para `"24.05"` para corresponder à versão do canal utilizado, conforme exigido pela documentação do NixOS.

### Hardening do kernel

**Arquivo:** `modules/features/system-hardening.nix`

Adicionadas restrições de kernel conforme o [NixOS Security Wiki](https://wiki.nixos.org/wiki/Security):

- `kernel.dmesg_restrict = 1`: Restringe acesso ao log do kernel apenas para root.
- `kernel.kptr_restrict = 2`: Oculta endereços de kernel de usuários não privilegiados.

---

## Etapa 3 — Performance e Precisão

### Kernel Zen mantido

**Arquivo:** `modules/hosts/my-machine/configuration.nix`

O `linuxPackages_zen` foi mantido como escolha deliberada para melhor responsividade em desktop, evitando kernels experimentais como o CachyOS que trocam estabilidade por patches agressivos.

### Remoção da re-importação do nixpkgs no niri.nix

**Arquivo:** `modules/features/niri.nix`

O bloco `_module.args.pkgs = import inputs.nixpkgs { ... }` foi removido. Essa re-importação criava uma instância separada e inconsistente do nixpkgs, podendo causar builds duplicados e versões divergentes de pacotes. O `pkgs` passado pelo flake-parts já é a instância correta.

---

## Etapa 4 — Home Manager: Neovim, Alacritty e XDG

### Neovim — Java/Spring Boot + GitHub Dark

**Arquivo:** `home/livara.nix`

Configuração declarativa completa do Neovim com:

- **Tema:** `github-nvim-theme` com `colorscheme github_dark` e background transparente (`guibg=NONE`) para adaptar ao terminal.
- **LSP Java:** `nvim-jdtls` + `nvim-lspconfig` para suporte a Spring Boot (detecta `pom.xml`, `gradle.build`).
- **Autocomplete:** `nvim-cmp` + `cmp-nvim-lsp` + `luasnip`.
- **Syntax:** `nvim-treesitter` com todas as gramáticas.
- **Dependências no sistema:** `jdt-language-server` e `spring-boot-cli` adicionados ao `systemPackages`.

### Alacritty — GitHub Dark + Padding

**Arquivo:** `home/livara.nix`

Configuração declarativa com:

- Paleta de cores GitHub Dark oficial (`#0d1117` como background).
- Padding de 10px em x e y com `dynamic_padding = true`.
- Sem decorações de janela (`decorations = "none"`).
- Sem fastfetch nem scripts de inicialização.

### Bash com autocomplete

**Arquivo:** `home/livara.nix`

`programs.bash.enableCompletion = true` habilita o bash-completion para produtividade no terminal.

### Diretórios XDG em inglês

**Arquivo:** `home/livara.nix`

`xdg.userDirs` configurado com todos os diretórios em inglês (Desktop, Documents, Downloads, Music, Pictures, Public, Templates, Videos).

---

## Etapa 5 — Aparência, Nautilus e Ícones

### Associações de arquivos via xdg.mimeApps

**Arquivo:** `home/livara.nix`

Configuração declarativa das associações MIME:

- Arquivos de programação (`.java`, `.py`, `.json`, `.html`, `.css`, `.js`) → Neovim no Alacritty.
- PDF → Okular.
- EPUB → Foliate.

### Desktop entry do Neovim

**Arquivo:** `home/livara.nix`

Criado `xdg.desktopEntries.nvim` que executa `alacritty -e nvim %F`, permitindo que o Nautilus abra arquivos de programação corretamente no Neovim dentro do Alacritty.

### Ícones do Noctalia reduzidos

**Arquivo:** `modules/features/noctalia.json`

- `iconScale` do widget Workspace: `0.8` → `0.7`.
- `pillSize`: `0.6` → `0.5`.
- `iconScale` do Tray: adicionado `0.7`.
- `size` do dock: `0.71` → `0.65`.
- `contentPadding`: `6` → `4`.
- `fontScale`: `1` → `0.9`.

### Correção do ícone do AudioRelay no tray

**Arquivo:** `modules/features/audiorelay.nix`

Adicionada variável de ambiente `XDG_CURRENT_DESKTOP = "GNOME"` no override do Flatpak do AudioRelay. Isso força o uso do protocolo StatusNotifierItem (appindicator), que é compatível com o Noctalia, corrigindo o ícone quebrado na barra de sistema.

---

## Estrutura Final do Repositório

```
nix-conf/
├── flake.nix                          # Inputs: nixpkgs 24.05, home-manager 24.05, flake-parts, nix-flatpak
├── flake.lock
├── home/
│   └── livara.nix                     # Configuração do usuário (Home Manager)
├── modules/
│   ├── parts.nix                      # Plataformas suportadas
│   ├── features/
│   │   ├── audiorelay.nix             # Módulo customizado AudioRelay + PipeWire
│   │   ├── desktop-portals.nix        # Polkit, keyring, XDG portals
│   │   ├── flatpak.nix                # Flatpak + apps
│   │   ├── greeter.nix                # Regreet (login screen)
│   │   ├── keyd.nix                   # Remapeamento de teclado
│   │   ├── niri.nix                   # Compositor Niri
│   │   ├── noctalia.json              # Configuração da barra Noctalia
│   │   ├── noctalia.nix               # Wrapper do Noctalia
│   │   ├── nvidia.nix                 # Driver NVIDIA legacy_580
│   │   └── system-hardening.nix      # Segurança, GC, zram, sysctl
│   └── hosts/
│       └── my-machine/
│           ├── configuration.nix      # Configuração principal do sistema
│           ├── default.nix            # nixosSystem + Home Manager
│           └── hardware.nix           # Hardware gerado pelo nixos-generate-config
├── Icons/
└── Wallpapers/
```

186	
187	## Etapa 6 — Finalização do Neovim, Alacritty e Tray (Jul 2026)
188	
189	### Neovim como IDE Completa (Refatorado)
190	
191	**Arquivo:** `home/livara.nix`
192	
193	- **Limpeza de Plugins:** Removidas duplicatas e pacotes de sistema (LSP servers) que estavam incorretamente na lista de plugins do Neovim.
194	- **Migração para extraLuaConfig:** Toda a configuração do Neovim agora utiliza `programs.neovim.extraLuaConfig`, eliminando problemas de escape de caracteres e blocos heredoc `lua << EOF`.
195	- **Suporte Java/Spring Boot:** Configuração completa do `nvim-java` com Lombok, testes, debug e ferramentas de Spring Boot. O `jdtls` agora detecta automaticamente a pasta `~/Projects`.
196	- **LSP Multi-linguagem:** Configurado suporte para C++ (`clangd`), Python (`pyright`), HTML, CSS e TypeScript/JavaScript.
197	- **Interface e Navegação:** 
198	  - `dashboard-nvim` com tema hyper e header ASCII elegante.
199	  - `nvim-tree` configurado para toggle com `<leader>e`.
200	  - `lualine` com tema GitHub Dark e status global.
201	  - Mapeamentos de teclas para navegação entre janelas (`<C-h/j/k/l>`) e atalhos para Telescope e Java.
202	
203	### Alacritty com Nerd Font
204	
205	**Arquivo:** `home/livara.nix`
206	
207	- **Fontes:** Adicionado o pacote `nerdfonts.override { fonts = [ "JetBrainsMono" ]; }` para suporte a ícones no Neovim e barra.
208	- **Configuração:** O Alacritty agora utiliza explicitamente "JetBrainsMono Nerd Font".
209	
210	### Correção Definitiva do Tray e AudioRelay
211	
212	**Arquivo:** `modules/features/audiorelay.nix`
213	
214	- **D-Bus:** Adicionada a variável `DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus"` ao ambiente do Flatpak do AudioRelay. Isso garante que o aplicativo consiga se comunicar corretamente com o barramento de sessão para registrar o ícone no tray do Noctalia.
215	
216	### Verificação de Compatibilidade 24.05
217	
218	- Verificados todos os pacotes e opções nos arquivos `greeter.nix` e `keyd.nix` para garantir que são compatíveis com o canal `nixos-24.05`.
219	
