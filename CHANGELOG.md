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

## [Unreleased] - Correções e Melhorias (2026-08-04)

### Changed
- **Browser**: Substituído Brave por Helium Browser. Adicionado flake `inputs.helium` (overlay `pkgs.helium`) em ambos os hosts. Keybind `Mod+W` agora spawn Helium.

### Added
- **Wallpapers Management**: Adicionado script de ativação no home-manager para clonar e atualizar automaticamente o repositório `Wallpapers` em `~/Wallpapers`.
- **Vault Management**: Configurado `services.git-sync` no home-manager para sincronização bidirecional automática do repositório Obsidian Vault em `~/Vault`.

### Changed
- **Home Manager Configuration**: Removido symlink manual antigo para Wallpapers; `home.nix` agora gerencia Wallpapers e Vault via Git de forma declarativa.

### Fixed
- **Niri Hotkey Overlay**: Corrigida a sintaxe da opção para desativar o overlay de hotkeys do Niri (`hotkey-overlay.skip-at-startup = true` no `shell-conf`).
- **Limpeza de Repositório**: Removido o arquivo `ARCHITECTURE_REVIEW_REPORT.md` e o symlink físico de wallpapers no repositório `nix-conf`, conforme solicitado.
- **DMS Keybinds**: Adicionados keybinds faltantes no Niri: `Mod+F` para maximizar coluna (maximize-column), `Mod+Shift+F` para tela cheia (fullscreen-window). O `Alt+Tab` já estava corretamente configurado para o switcher do DMS.
- **DMS JSON Persistence**: Refatorado `dms.nix` no `shell-conf` para usar `mkOutOfStoreSymlink` para `settings.json` e `session.json`, apontando para arquivos mutáveis dentro do próprio clone do repositório `shell-conf`. Isso permite que edições feitas via interface do DMS persistam e sejam versionadas no Git.
- **DMS Power Menu**: O power menu em runtime do DMS (`Mod+X`) já possui as dependências necessárias (`power-profiles-daemon`, `accounts-daemon`) garantidas pelo módulo NixOS do DMS, sem conflitar com o SDDM (tema Clockwork) que continua sendo o gerenciador de login padrão.
