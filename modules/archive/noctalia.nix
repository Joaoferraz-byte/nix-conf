# ─── Noctalia Wrapper ─────────────────────────────────────────────────────
{ self, inputs, ... }: {
  perSystem =
    { pkgs, lib, ... }:
    let
      baseSettings = builtins.fromJSON (builtins.readFile ./noctalia.json);

      targetMonitor = "HDMI-A-1";

      baseSettingsFile = pkgs.writeText "noctalia-base-settings.json" (builtins.toJSON baseSettings);
    in
    {
      packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
        inherit pkgs;
        settings = baseSettings;
      };

      packages.myNoctaliaWithFlatpakIcons = pkgs.writeShellScriptBin "noctalia-wrapper" ''
        export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
        exec ${self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia}/bin/noctalia-shell "$@"
      '';

      packages.myNoctaliaDynamicMonitor = pkgs.writeShellApplication {
        name = "noctalia-dynamic-monitor";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          set -euo pipefail

          target_monitor="${targetMonitor}"
          base_settings="${baseSettingsFile}"
          runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}/noctalia"
          out_settings="$runtime_dir/settings.json"

          mkdir -p "$runtime_dir"

          monitor_present="false"
          if command -v niri >/dev/null 2>&1; then
            if niri msg -j outputs 2>/dev/null \
                | jq -e --arg m "$target_monitor" 'has($m)' >/dev/null 2>&1; then
              monitor_present="true"
            fi
          fi

          if [ "$monitor_present" = "true" ]; then
            jq --arg m "$target_monitor" '
              .bar.monitors = [$m]
              | .dock.monitors = [$m]
              | .notifications.monitors = [$m]
              | .osd.monitors = [$m]
            ' "$base_settings" > "$out_settings"
          else
            cp "$base_settings" "$out_settings"
          fi

          export NOCTALIA_SETTINGS_FILE="$out_settings"
          export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:''${XDG_DATA_DIRS:-}"
          exec ${self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia}/bin/noctalia-shell "$@"
        '';
      };
    };
}
