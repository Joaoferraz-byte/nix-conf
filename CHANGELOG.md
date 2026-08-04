# Changelog

## Migration: Ambxst → DankMaterialShell + Niri

O shell Ambxst-X foi substituído por DankMaterialShell (DMS) + Niri compositor. A integração é feita via flake `shell-conf`.

**Removido:**
- `modules/features/ambxst.nix`, `modules/features/hyprland.nix`
- `modules/features/shell.nix`, todos os scripts auxiliares
- Referências a Ambxst, axctl e Hyprland Lua

**Adicionado:**
- `inputs.shell-conf` no flake.nix (DMS + Niri via upstream)
- Host `latitude` (Dell Latitude 5410)
- Overlays para `gradience` stub e `gnome-icon-theme`

**Alterado:**
- `home/livara/home.nix`: terminal de Alacritty para Wezterm
- `modules/packages/core-packages.nix`: pacotes atualizados para DMS/Niri
- SDDM: tema reescrito para Clockwork

## Refatoração de organização

- Módulo `system-hardening` adicionado ao `configuration.nix`.
- `hardware.opengl` → `hardware.graphics` (sintaxe moderna).
- `stateVersion` atualizado para `26.11`.
