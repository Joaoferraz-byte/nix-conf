# Changelog

## [2026-07-30] Migração para Hyprland + Ambxst-X

### Alterações Principais
- **Compositor**: Migração completa do Niri para o Hyprland.
- **Shell**: Substituição do Noctalia pelo Ambxst-X (vendored via `shell-conf`).
- **Login Manager**: Substituição do tema Noctalia pelo tema Astronaut no SDDM.
- **Arquitetura**: Remoção de módulos legados e simplificação de inputs do flake.

### Detalhes Técnicos
- Adicionado módulo `hyprland.nix` com suporte a **UWSM**.
- Atualizado `ambxst.nix` para integrar com Hyprland via `axctl`.
- Removido `niri.nix`, `shell.nix` e diretório `modules/archive/`.
- Removidos inputs `nixpkgs-stable` e `wrapper-modules` do `flake.nix`.
- Mapeadas configurações JSON do usuário para `~/.config/ambxst/config/`.

---

## Refatoração de organização e modularidade

### Estrutura
- `ARCHITECTURE.md` atualizado para refletir a arquitetura atual.
- `ARCHITECTURE_REVIEW_REPORT.md` reescrito com as revisões arquiteturais aplicadas até agora.
- Módulo `system-hardening` ativado no `configuration.nix`.

### Auditoria de segurança e hardening
- Política padrão `DROP` configurada explicitamente.
- mDNS (UDP 5353) permitido.
- Hardening do kernel e desativação de redirecionamentos ICMP.
- Journald configurado com limites de armazenamento e retenção.

---

## Correção do erro de compilação (attribute 'nixvim' missing)

### Home Manager
- Desktop entry do Neovim corrigido para referenciar o pacote do flake `vim-conf`.
- Parâmetro `lib` adicionado ao escopo de `home.nix`.

---

## Migração para nixos-unstable

### Gráficos
- `hardware.opengl` -> `hardware.graphics` (sintaxe moderna do NixOS).
- `driSupport32Bit` -> `enable32Bit` dentro de `hardware.graphics`.

### NVIDIA
- Driver `legacy_580` para GPUs Pascal.

### Home Manager
- `stateVersion` atualizado para `26.11`.
