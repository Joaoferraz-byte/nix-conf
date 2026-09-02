# Stylix Home Manager integration
#
# Architectural rationale (research: research/stylix-overlays-research.md)
# -----------------------------------------------------------------------
# stylix/overlays.nix injects `config.nixpkgs.overlays = [ attrs.overlay ]`
# into BOTH the NixOS module (stylix/nixos/default.nix) and the Home Manager
# module (stylix/hm/default.nix), guarded by `stylix.overlays.enable`
# (default = config.stylix.autoEnable = true).
#
# With home-manager.useGlobalPkgs = true, HM reuses the SAME nixpkgs instance
# as NixOS (nixos-and-flakes book: "kept consistent with inputs.nixpkgs ...
# to avoid problems caused by different versions of nixpkgs").  Setting
# `nixpkgs.*` options in the HM context is therefore rejected (home-manager
# Issue #9575, NUR #877, Discourse #60505), which surfaces as the build error:
#
#   Definitions found in modules/nixos-icons/overlay.nix
#   and modules/gtksourceview/overlay.nix
#
# NixOS philosophy is declarative single-source-of-truth (ekala nix-book:
# the entire OS is one derivation; nixos-and-flakes: "manage the static
# portion of the system state in a declarative manner").  Overlays modify the
# pkgs instance (the derivation), not user configuration (nixcademy overlays
# article).  Because useGlobalPkgs makes HM share the NixOS pkgs instance,
# the overlays ALREADY apply to every package HM installs — re-injecting them
# in the HM module is redundant AND prohibited.
#
# Setting `stylix.overlays.enable = false` HERE (HM context only) does NOT
# remove the overlays from the system: they remain applied at the NixOS level
# (stylix/nixos).  It only stops the redundant, conflicting re-injection in
# HM, which is the root cause of the error and, conceptually, a duplication of
# the single source of truth.  Stylix theming is unaffected because
# stylix.homeManagerIntegration.followSystem (default true) keeps HM theming
# derived from the NixOS stylix config, and the themed packages come from the
# shared global pkgs.
#
# This is therefore the fix that aligns with both the NixOS declarative
# philosophy and home-manager's useGlobalPkgs architecture — NOT a removal of
# the overlay from the system.
{
  # Disable stylix's overlay re-injection in the Home Manager context.
  # The overlays remain active at the NixOS level (single source of truth).
  stylix.overlays.enable = false;
}
