# ─── Noctalia Wrapper [ARCHIVED] ──────────────────────────────────────────
# Este módulo foi arquivado durante a migração de Niri → Hyprland.
# Ele dependia do input `wrapper-modules` (github:BirdeeHub/nix-wrapper-modules),
# que foi removido do flake.nix em e72471c ("feat: migrate to Hyprland").
#
# O wrapper Noctalia fornecia:
#   - packages.myNoctalia: wrapper para o shell Noctalia
#   - packages.myNoctaliaWithFlatpakIcons: wrapper com Flatpak icons
#   - packages.myNoctaliaDynamicMonitor: wrapper com detecção de monitor
#
# Se necessário no futuro, o wrapper-modules pode ser readicionado ao flake.nix:
#   wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
# E este arquivo restaurado com a configuração original.
{ ... }: { }
