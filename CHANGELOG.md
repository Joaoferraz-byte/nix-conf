# Changelog

## Revisão de arquitetura e limpeza técnica

### Flake

- `home-manager` fixado na `master` com `inputs.nixpkgs.follows = "nixpkgs"` — corresponde ao canal `nixos-unstable`.
- Entrada `nixpkgs-stable` mantida como pino de segurança para o `niri` contra falhas transientes de build da `libdisplay-info` no `nixos-unstable`.
- `perSystem` define `_module.args.pkgs` com `allowUnfree = true` — fonte única para pacotes proprietários.
- Corrigido erro de licença NVIDIA adicionando `allowUnfree = true` na definição do `nixosSystem` no `default.nix`.

### Niri

- Removido `v2-settings = true` depreciado — o módulo wrapper ativa as configurações v2 por padrão.
- Removido `overrideAttrs` redundante para `providedSessions` — o wrapper passa `providedSessions` automaticamente.
- Blur de fundo mantido (`background-effect { blur = true }`, válido desde niri 26.04).

### AudioRelay

- Restaurado `XDG_CURRENT_DESKTOP = "GNOME"` e `DBUS_SESSION_BUS_ADDRESS` — força o protocolo StatusNotifierItem para que o ícone da bandeja renderize no Noctalia.
- Movido `security.rtkit.enable` de `desktop-portals.nix` para cá — o rtkit pertence ao PipeWire.

### Portais Desktop

- Removido `security.rtkit.enable` (movido para `audiorelay.nix`).

### Home Manager

- Migração do Neovim para um módulo NixOS via `nix-wrapper-modules`.
- Separação da configuração Lua para o repositório externo `lua-conf`.
- Removida a instalação manual do Neovim e `JAVA_HOME` do `home.nix`, agora gerenciados pelo wrapper.
- Adicionado `home-manager.backupFileExtension = "backup"` para resolver conflitos de arquivos existentes (ex: `mimeapps.list`) durante a ativação.
- `stateVersion` atualizado para `26.11` em todo o sistema.

### Estrutura

- Removido sistemas darwin do `parts.nix` — este é um desktop NVIDIA apenas Linux.
- Indentação normalizada para 2 espaços em `hardware.nix` e `flatpak.nix`.
- Removido importação duplicada do módulo `home-manager` e `allowUnfree` duplicado do `configuration.nix`.
- Removido bloco `meta:M` vazio de `keyd.nix`.
- Ativado módulo `keyd.nix` no `configuration.nix`.
- Traduzido todos os comentários e descrições de inglês para português.

---

## Migração para nixos-unstable

### Gráficos

- `hardware.opengl` -> `hardware.graphics` (sintaxe moderna do NixOS).
- `driSupport32Bit` -> `enable32Bit` dentro de `hardware.graphics`.

### NVIDIA

- Driver `legacy_580` para GPUs Pascal.

### Home Manager

- `stateVersion` atualizado para `26.11`.

---

## Modularização inicial

- Home Manager integrado ao flake via `home-manager.nixosModules.home-manager` com `useGlobalPkgs` e `useUserPackages`.
- Configuração do usuário centralizada em `home/livara/home.nix` (Neovim agora é um módulo de sistema).
- Módulos de recursos em `modules/features/`, configuração do host em `modules/hosts/my-machine/`.
