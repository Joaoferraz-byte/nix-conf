# Changelog

## [Unreleased] - 2026-08-06

### Fixed
- **Latitude ACPI Mitigation**: Use the regular stable Nixpkgs kernel instead of `linuxPackages_latest`; the reported `_TZ.ETMD`/`_OSC` messages are firmware ACPI-table defects exposed during kernel evaluation, so no unsafe `acpi_osi` override is forced.
- **Removable Media Automount**: Enable the system `udisks2` service so the user-session `udiskie` service can automatically mount USB and other removable devices for Nautilus.
- **DMS Session Reload**: Restart the active user-level DMS service after Home Manager writes the declarative session and wallpaper directory, ensuring wallpaper cycling settings are consumed without a manual service restart.
- **Wallpaper Verification**: DMS v1.5.3 provides a native wallpaper scheduler; verification should use the generated session JSON, service logs, scheduler cache, and a manual IPC cycle before introducing an external timer.
- **Zen Browser DMS Theme**: Replaced `@import url("file://...")` in `userChrome.css` with a runtime symlink (`~/.config/zen/default/chrome/userChrome.css` → `~/.config/DankMaterialShell/zen.css`) via `home.activation.linkZenTheme`, resolving Chrome CSP blocking of `file://` imports in the chrome context
- **Wallpaper Cycling**: Declarative session config in `home.nix` with `wallpaperCyclingEnabled = true`, interval 900s (15 min), mode `interval`
- **Zen Browser Preferences**: Shell-conf module now includes modern Zen preferences (floating URL bar, smooth scrolling, workspace session restore)

## Migration: Ambxst → DankMaterialShell + Niri

O shell Ambxst-X foi substituído por DankMaterialShell (DMS) + Niri compositor. A integração é feita via flake `shell-conf`.

**Removido:**
- `modules/features/ambxst.nix`, `modules/features/hyprland.nix`
- `modules/features/shell.nix`, todos os scripts auxiliares
- Referências a Ambxst, axctl e Hyprland Lua

**Adicionado:**
- `inputs.shell-conf` no flake.nix (DMS + Niri via upstream)
- Host `latitude` (Dell Latitude 5410)
- Overlays para `gradience` stub

**Alterado:**
- `home/livara/home.nix`: terminal de Alacritty para Wezterm
- `modules/packages/core-packages.nix`: pacotes atualizados para DMS/Niri
- SDDM: tema reescrito para Clockwork

## Refatoração de organização

- Módulo `system-hardening` adicionado ao `configuration.nix`.
- `hardware.opengl` → `hardware.graphics` (sintaxe moderna).
- `stateVersion` atualizado para `26.11`.

## Correções e Melhorias (2026-08-05)

### Fixed
- **Cursor Bibata no Niri**: Removido `home.pointerCursor` e `gtk.cursorTheme` (gambiarra). Agora usa o bloco nativo `cursor { xcursor-theme; xcursor-size; }` do Niri. Configurado via DMS `cursorSettings` no JSON.
- **Cursor SDDM**: Removidas variáveis `XCURSOR_THEME` e `XCURSOR_SIZE` do `greeter.nix` (redundantes com o tema SDDM).
- **Host Latitude — input.helium**: Removido `inputs.helium.overlays.default` (referência a input inexistente). Overlay `gnome-icon-theme` também removido.
- **Host Latitude — keyboard**: Corrigido layout de teclado de `ie` para `br`/`abnt2` com locales `pt_BR`.
- **Host Latitude — configuration duplicada**: Removida duplicação de blocos `services.xserver.xkb` e `services.tlp`.
- **Zen Browser declaração dupla**: Removido pacote direto `inputs.zen-browser.packages."${pkgs.system}".default` e desktop entry manual. Agora usa `inputs.zen-browser.homeModules.beta` com `programs.zen-browser.enable`.
- **Vault Sync**: Adicionado `home.activation.cloneVault` para clonar o repositório na primeira ativação. Adicionado `.gitignore` no Vault para excluir `plugins/`, `themes/` e `_attachments/`.
- **WezTerm**: Removida confirmação de fechamento para shells (`zsh`, `bash`, `fish`, `nu`).

### Added
- **DMS Plugins**: Declarados via `dms-plugin-registry` — `quickCapture`, `screenCapture`, `dankQuickSearch`.
- **Keybind Quick Capture**: `Super+Shift+S` → spawn `dms ipc plugin quickCapture capture`.
- **Wallpaper Cycling**: Ativado no `dms-session.json` com intervalo de 900s (15 min), modo random.
- **Fastfetch**: Configurado via `xdg.configFile` no shell-conf com logo NixOS small.
- **DMS Session**: Removido `helium` do `browserUsageHistory`, nome do Zen Browser corrigido de "Zen Browser (Beta)" para "Zen Browser".
- **Pacotes**: Adicionados `inotify-tools` e `fastfetch` ao `core-packages.nix`.

### Changed
- **Home Manager Configuration**: `home.nix` reorganizado por categorias (Imports, Home Profile, Environment, Programs, Packages, Desktop Entries, Mime, Git Repositories).
- **CHANGELOG**: Removida referência ao Helium Browser (substituído pelo Zen Browser).
