# ─── SDDM Display Manager + Clockwork Theme ─────────────────────────────────
# The Clockwork theme is vendored locally in ./themes/clockwork/
# and built as a Nix derivation (pkgs.stdenv.mkDerivation).
#
# Reference: OrynVail/OrynOS modules/core/sddm.nix
#
# This module:
#   1. Builds the Clockwork SDDM theme from local sources
#   2. Enables SDDM with Wayland support
#   3. Sets the theme to "clockwork"
#   4. Adds Qt6/KDE dependencies required by the QML theme
#   5. Sets Bibata-Modern-Classic cursor theme for the greeter
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, lib, ... }:
    let
      # ── Clockwork SDDM Theme Derivation ────────────────────────────────
      # Vendored locally from OrynVail/OrynOS/themes/clockwork
      # (Originally authored by Darkkal44, part of the qylock collection)
      clockworkTheme = pkgs.stdenv.mkDerivation {
        name = "clockwork-sddm-theme";
        src = ../../themes/clockwork;
        installPhase = ''
          mkdir -p $out/share/sddm/themes/clockwork
          cp -aR $src/* $out/share/sddm/themes/clockwork/
        '';
      };
      # Qt6/KDE dependencies required by the Clockwork QML theme
      # The theme imports: QtQuick, QtQuick.Window, Qt5Compat.GraphicalEffects,
      # Qt.labs.folderlistmodel, SddmComponents
      sddmDependencies = with pkgs.kdePackages; [
        qt5compat
        qtdeclarative
        qtmultimedia
        qtsvg
        qtvirtualkeyboard
      ];
    in {
      # ── SDDM Display Manager ─────────────────────────────────────────────
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        theme = "clockwork";
        extraPackages = sddmDependencies;
        settings = {
          Theme = {
            CursorTheme = "Bibata-Modern-Classic";
          };
        };
      };

      # ── Install the Clockwork theme and cursor package ──────────────────
      environment.systemPackages = [
        clockworkTheme
        pkgs.bibata-cursors
      ];

      # ── Cursor theme for the greeter session ────────────────────────────
      environment.variables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "20";
      };

      # ── Gnome Keyring integration for SDDM ──────────────────────────────
      security.pam.services.sddm.enableGnomeKeyring = true;

      services.accounts-daemon.enable = true;
    };
}
