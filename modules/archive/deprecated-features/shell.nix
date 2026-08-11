# ─── Quickshell Integration [DEPRECATED — REMOVED] ────────────────────────
# Este módulo foi removido. O Ambxst shell substitui o Noctalia/Quickshell.
# O módulo ambxst.nix fornece integração completa com o Ambxst, incluindo
# fontes, serviços (upower, power-profiles-daemon) e o módulo Home Manager.
#
# Se você precisa da integração antiga, use self.nixosModules.ambxst.
{ ... }: {
  flake.nixosModules.quickshell = { ... }: {
    # This module is intentionally empty. It exists only for backwards
    # compatibility in case any external reference imports it.
    # Use self.nixosModules.ambxst instead.
  };
}
