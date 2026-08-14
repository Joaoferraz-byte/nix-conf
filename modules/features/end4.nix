{ inputs, ... }:
{
  flake.homeModules = {
    hyprland = { pkgs, ... }:
      {
        home.pointerCursor = {
          enable = true;
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;
          gtk.enable = true;
          x11.enable = true;
        };

        wayland.systemd.target = "graphical-session.target";
      };

    end4 = { config, lib, pkgs, ... }:
      let
        dotfiles = inputs.illogical-impulse-dotfiles;
        source = path: builtins.toPath "${dotfiles}/dots/.config/${path}";
        quickshell = inputs.quickshell.packages.${pkgs.system}.default;
        pythonEnv = pkgs.python3.withPackages (pythonPackages: [
          pythonPackages.materialyoucolor
          pythonPackages.pillow
        ]);
        polkitAgent = lib.getExe pkgs.kdePackages.polkit-kde-agent-1;
        home = config.home.homeDirectory;

        quickshellConfig = pkgs.runCommand "end4-quickshell-ii" { } ''
          cp -R ${source "quickshell/ii"} "$out"
          chmod -R u+w "$out"
          for script in \
            "$out/scripts/colors/generate_colors_material.py" \
            "$out/scripts/hyprland/get_keybinds.py" \
            "$out/scripts/wayland-idle-inhibitor.py"; do
            if [ -f "$script" ]; then
              sed -i '1c\\#!/usr/bin/env python3' "$script"
            fi
          done
        '';

        recordScript = pkgs.writeShellScript "end4-record" ''
          set -euo pipefail

          getdate() {
            date '+%Y-%m-%d_%H.%M.%S'
          }

          getactive_monitor() {
            hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
          }

          video_dir="$(xdg-user-dir VIDEOS 2>/dev/null || true)"
          if [[ -z "$video_dir" || "$video_dir" == "$HOME" ]]; then
            video_dir="$HOME/Videos"
          fi
          mkdir -p "$video_dir"
          cd "$video_dir"

          if pgrep -x gpu-screen-recorder >/dev/null; then
            notify-send "Recording stopped" "Saved in $video_dir" -a Recorder || true
            pkill -SIGINT -x gpu-screen-recorder
            exit 0
          fi

          output="$video_dir/recording_$(getdate).mp4"
          audio_args=()
          capture_args=()
          case "''${1:-}" in
            --fullscreen-sound)
              audio_args=(-a default_output)
              capture_args=(-w "$(getactive_monitor)")
              ;;
            --fullscreen)
              capture_args=(-w "$(getactive_monitor)")
              ;;
            --sound)
              audio_args=(-a default_output)
              ;;
            *)
              if ! region="$(slurp -f '%wx%h+%x+%y')"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a Recorder || true
                exit 1
              fi
              capture_args=(-w region -region "$region")
              ;;
          esac

          notify-send "Starting recording" "$output" -a Recorder || true
          exec gpu-screen-recorder "''${capture_args[@]}" -f 60 -k h264 -c mp4 "''${audio_args[@]}" -o "$output"
        '';

        hyprlandScripts = pkgs.runCommand "end4-hyprland-scripts" { } ''
          cp -R ${source "hypr/hyprland/scripts"} "$out"
          chmod -R u+w "$out"
          cp ${recordScript} "$out/record.sh"
          chmod +x "$out/record.sh"
        '';

        customScripts = pkgs.runCommand "end4-custom-scripts" { } ''
          cp -R ${source "hypr/custom/scripts"} "$out"
          chmod -R u+w "$out"
        '';

        seedRuntime = pkgs.writeShellScript "seed-end4-runtime" ''
          set -eu

          config_dir="${home}/.config"
          state_dir="${config.xdg.stateHome}/quickshell/user/generated"
          venv_dir="${config.xdg.stateHome}/quickshell/.venv"
          mkdir -p \
            "$config_dir/hypr/hyprland" \
            "$config_dir/hypr/hyprland/shellOverrides" \
            "$config_dir/hypr/custom/scripts" \
            "$config_dir/hypr/hyprlock" \
            "$config_dir/gtk-3.0" \
            "$config_dir/gtk-4.0" \
            "$config_dir/fuzzel" \
            "$config_dir/matugen/templates/hyprland" \
            "$config_dir/matugen/templates/gtk-3.0" \
            "$config_dir/matugen/templates/gtk-4.0" \
            "$config_dir/illogical-impulse"
          mkdir -p "$state_dir/wallpaper" "$venv_dir/bin"
          printf '%s\n' \
            'export VIRTUAL_ENV="${config.xdg.stateHome}/quickshell/.venv"' \
            'export PATH="${pythonEnv}/bin:$PATH"' \
            'hash -r 2>/dev/null || true' > "$venv_dir/bin/activate"

          for output in \
            "$config_dir/hypr/hyprland/colors.lua" \
            "$config_dir/hypr/hyprlock/colors.conf" \
            "$config_dir/fuzzel/fuzzel_theme.ini" \
            "$config_dir/gtk-3.0/gtk.css" \
            "$config_dir/gtk-4.0/gtk.css"; do
            if [ -L "$output" ]; then
              rm -f "$output"
            fi
          done

          if [ ! -e "$config_dir/hypr/hyprland/colors.lua" ]; then
            cp "${source "hypr/hyprland/colors.lua"}" "$config_dir/hypr/hyprland/colors.lua"
          fi
          if [ ! -e "$config_dir/hypr/hyprland/shellOverrides/main.lua" ]; then
            cp "${source "hypr/hyprland/shellOverrides/main.lua"}" "$config_dir/hypr/hyprland/shellOverrides/main.lua"
          fi
          if [ ! -e "$config_dir/hypr/hyprlock.conf" ]; then
            cp "${source "hypr/hyprlock.conf"}" "$config_dir/hypr/hyprlock.conf"
          fi
          if [ ! -e "$config_dir/hypr/hyprlock/colors.conf" ]; then
            cp "${source "hypr/hyprlock/colors.conf"}" "$config_dir/hypr/hyprlock/colors.conf"
          fi
          if [ ! -e "$config_dir/fuzzel/fuzzel_theme.ini" ]; then
            cp "${source "matugen/templates/fuzzel/fuzzel_theme.ini"}" "$config_dir/fuzzel/fuzzel_theme.ini"
          fi
          if [ ! -e "$config_dir/gtk-3.0/gtk.css" ]; then
            cp "${source "matugen/templates/gtk-3.0/gtk.css"}" "$config_dir/gtk-3.0/gtk.css"
          fi
          if [ ! -e "$config_dir/gtk-4.0/gtk.css" ]; then
            cp "${source "matugen/templates/gtk-4.0/gtk.css"}" "$config_dir/gtk-4.0/gtk.css"
          fi
        '';
      in
      {
        gtk = {
          enable = true;
          iconTheme = {
            package = pkgs.kora-icon-theme;
            name = "Kora";
          };
        };

        qt = {
          enable = true;
          platformTheme.name = "kde";
        };

        home.sessionVariables = {
          ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${config.xdg.stateHome}/quickshell/.venv";
          QS_CONFIG = "ii";
        };

        home.packages = with pkgs; [
          quickshell
          pythonEnv
          brightnessctl
          cliphist
          eza
          foot
          fuzzel
          grim
          grimblast
          hypridle
          hyprlock
          hyprpicker
          hyprshot
          hyprsunset
          gpu-screen-recorder
          easyeffects
          libnotify
          jq
          libqalculate
          matugen
          mpv
          playerctl
          ripgrep
          satty
          slurp
          swappy
          tesseract
          upower
          wlogout
          xdg-user-dirs
          wl-clip-persist
          wl-clipboard
          wtype
          ydotool
          kdePackages.kdialog
          kdePackages.qt5compat
          kdePackages.qtbase
          kdePackages.qtdeclarative
          kdePackages.qtimageformats
          kdePackages.qtmultimedia
          kdePackages.qtpositioning
          kdePackages.qtquicktimeline
          kdePackages.qtsensors
          kdePackages.qtsvg
          kdePackages.qttools
          kdePackages.qttranslations
          kdePackages.qtvirtualkeyboard
          kdePackages.qtwayland
          kdePackages.syntax-highlighting
          gnome-keyring
          libdbusmenu-gtk3
          material-symbols
          adw-gtk3
          bibata-cursors
        ];

        xdg.configFile = {
          "quickshell/ii".source = quickshellConfig;
          "hypr/hyprland/scripts".source = hyprlandScripts;
          "hypr/custom/scripts".source = customScripts;
          "hypr/hyprlock/check-capslock.sh".source = source "hypr/hyprlock/check-capslock.sh";
          "hypr/hyprlock/status.sh".source = source "hypr/hyprlock/status.sh";
          "hypr/fuzzel-emoji.sh".source = source "hypr/hyprland/scripts/fuzzel-emoji.sh";
          "hypr/snip_to_search.sh".source = source "hypr/hyprland/scripts/snip_to_search.sh";
          "fuzzel/fuzzel.ini".source = source "fuzzel/fuzzel.ini";
          "matugen/templates/colors.json".source = source "matugen/templates/colors.json";
          "matugen/templates/fuzzel/fuzzel_theme.ini".source = source "matugen/templates/fuzzel/fuzzel_theme.ini";
          "matugen/templates/gtk-3.0/gtk.css".source = source "matugen/templates/gtk-3.0/gtk.css";
          "matugen/templates/gtk-4.0/gtk.css".source = source "matugen/templates/gtk-4.0/gtk.css";
          "matugen/templates/hyprland/colors.lua".source = source "matugen/templates/hyprland/colors.lua";
          "matugen/templates/hyprland/hyprlock-colors.conf".source = source "matugen/templates/hyprland/hyprlock-colors.conf";
          "matugen/templates/kde/color.txt".source = source "matugen/templates/kde/color.txt";
          "matugen/templates/wallpaper.txt".source = source "matugen/templates/wallpaper.txt";
          "wlogout/layout".source = source "wlogout/layout";
          "wlogout/style.css".source = source "wlogout/style.css";
        };

        wayland.windowManager.hyprland.extraConfig = ''
          local hm_xdg_config_home = os.getenv("XDG_CONFIG_HOME") or "${config.xdg.configHome}"
          package.path = hm_xdg_config_home .. "/hypr/?.lua;" .. hm_xdg_config_home .. "/hypr/?/init.lua;" .. package.path
          ${builtins.readFile (source "hypr/hyprland.lua")}
        '';

        wayland.windowManager.hyprland.extraLuaFiles = {
          "hyprland/env.lua" = {
            content = builtins.readFile (source "hypr/hyprland/env.lua");
            autoLoad = false;
          };
          "hyprland/execs.lua" = {
            content = builtins.replaceStrings
              [
                "    hl.exec_cmd(\"hypridle\")"
                "    hl.exec_cmd(\"easyeffects --hide-window --service-mode\")"
              ]
              [
                "    hl.exec_cmd(\"hypridle\")"
                "    hl.exec_cmd(\"${polkitAgent}\")\n    hl.exec_cmd(\"easyeffects --hide-window --service-mode\")"
              ]
              (builtins.readFile (source "hypr/hyprland/execs.lua"));
            autoLoad = false;
          };
          "hyprland/general.lua" = {
            content = builtins.readFile (source "hypr/hyprland/general.lua");
            autoLoad = false;
          };
          "hyprland/keybinds.lua" = {
            content = builtins.readFile (source "hypr/hyprland/keybinds.lua");
            autoLoad = false;
          };
          "hyprland/lib/init.lua" = {
            content = builtins.readFile (source "hypr/hyprland/lib/init.lua");
            autoLoad = false;
          };
          "hyprland/rules.lua" = {
            content = builtins.readFile (source "hypr/hyprland/rules.lua");
            autoLoad = false;
          };
          "hyprland/services/init.lua" = {
            content = builtins.readFile (source "hypr/hyprland/services/init.lua");
            autoLoad = false;
          };
          "hyprland/services/create_custom_config.lua" = {
            content = builtins.readFile (source "hypr/hyprland/services/create_custom_config.lua");
            autoLoad = false;
          };
          "hyprland/variables.lua" = {
            content = builtins.replaceStrings
              [
                "'foot' 'kitty -1' 'alacritty' 'wezterm'"
                "'google-chrome-stable' 'zen-browser' 'firefox'"
              ]
              [
                "'wezterm' 'foot' 'kitty -1' 'alacritty'"
                "'zen-beta' 'zen-browser' 'firefox'"
              ]
              (builtins.readFile (source "hypr/hyprland/variables.lua"));
            autoLoad = false;
          };
          "custom/keybinds.lua" = {
            content = ''
              local mod = "SUPER"
              local qs = "qs -c $qsConfig ipc call "

              hl.bind(mod .. " + Comma", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/$qsConfig/settings.qml"))
              hl.bind(mod .. " + Space", hl.dsp.exec_cmd(qs .. "overviewToggle"))
              hl.bind(mod .. " + X", hl.dsp.exec_cmd(qs .. "sessionToggle"))
              hl.bind(mod .. " + D", hl.dsp.exec_cmd(qs .. "overviewToggle"))
              hl.bind(mod .. " + V", hl.dsp.exec_cmd(qs .. "overviewClipboardToggle"))
              hl.bind(mod .. " + N", hl.dsp.exec_cmd("zennotes"))
              hl.bind(mod .. " + Tab", hl.dsp.exec_cmd(qs .. "cheatsheetToggle"))

              hl.bind(mod .. " + W", hl.dsp.exec_cmd("zen-beta"))
              hl.bind(mod .. " + E", hl.dsp.exec_cmd("nautilus"))
              hl.bind(mod .. " + O", hl.dsp.exec_cmd("zennotes"))
              hl.bind(mod .. " + T", hl.dsp.exec_cmd("wezterm"))
              hl.bind(mod .. " + Return", hl.dsp.exec_cmd("wezterm"))
              hl.bind(mod .. " + C", hl.dsp.window.close())

              hl.bind(mod .. " + Left", hl.dsp.focus({ direction = "l" }))
              hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "r" }))
              hl.bind(mod .. " + Up", hl.dsp.focus({ direction = "u" }))
              hl.bind(mod .. " + Down", hl.dsp.focus({ direction = "d" }))
              hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
              hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

              hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty --filename - --copy-command wl-copy --early-exit"))
              hl.bind(mod .. " + S", hl.dsp.exec_cmd("grimblast --notify copy output"))
              hl.bind(mod .. " + CTRL + S", hl.dsp.exec_cmd("grimblast --notify copy active"))
              hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copy output"))
              hl.bind("CTRL + Print", hl.dsp.exec_cmd("mkdir -p \"$HOME/Pictures/Screenshots\" && grimblast --notify copysave output"))

              hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
              hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/quickshell/$qsConfig/scripts/colors/switchwall.sh"))
              hl.bind(mod .. " + CTRL + SHIFT + W", hl.dsp.exec_cmd("~/.config/quickshell/$qsConfig/scripts/colors/switchwall.sh"))
            '';
            autoLoad = false;
          };
        };

        home.activation.seedEnd4Runtime = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${seedRuntime}
        '';
      };
  };
}
