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
      quickshell = inputs.quickshell.packages.${pkgs.system}.default;
      pythonEnv = pkgs.python3.withPackages (pythonPackages: [
        pythonPackages.materialyoucolor
        pythonPackages.pillow
      ]);
      polkitAgent = lib.getExe pkgs.kdePackages.polkit-kde-agent-1;
      home = config.home.homeDirectory;
      source = path: "${dotfiles}/.config/${path}";
      quickshellConfig = pkgs.runCommand "end4-quickshell-ii" { } ''
        cp -R ${source "quickshell/ii"} "$out"
        chmod -R u+w "$out"
        for script in \
          "$out/scripts/colors/generate_colors_material.py" \
          "$out/scripts/hyprland/get_keybinds.py" \
          "$out/scripts/wayland-idle-inhibitor.py"; do
          sed -i '1c\\#!/usr/bin/env python3' "$script"
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
      hyprScripts = pkgs.runCommand "end4-hypr-scripts" { } ''
        cp -R ${source "hypr/hyprland/scripts"} "$out"
        chmod -R u+w "$out"
        cp ${recordScript} "$out/record.sh"
        chmod +x "$out/record.sh"
      '';
      seedRuntime = pkgs.writeShellScript "seed-end4-runtime" ''
        set -eu

        config_dir="${home}/.config"
        state_dir="${config.xdg.stateHome}/quickshell/user/generated"
        venv_dir="${config.xdg.stateHome}/quickshell/.venv"
        mkdir -p "$config_dir/hypr/hyprland" "$config_dir/hypr/custom/scripts" "$config_dir/gtk-3.0" "$config_dir/gtk-4.0" "$config_dir/fuzzel" "$config_dir/illogical-impulse"
        mkdir -p "$state_dir/wallpaper" "$venv_dir/bin"
        printf '%s\n' \
          'export VIRTUAL_ENV="${config.xdg.stateHome}/quickshell/.venv"' \
          'export PATH="${pythonEnv}/bin:$PATH"' \
          'hash -r 2>/dev/null || true' > "$venv_dir/bin/activate"

        for output in \
          "$config_dir/hypr/hyprland/colors.conf" \
          "$config_dir/hypr/hyprlock.conf" \
          "$config_dir/fuzzel/fuzzel_theme.ini" \
          "$config_dir/gtk-3.0/gtk.css" \
          "$config_dir/gtk-4.0/gtk.css"; do
          if [ -L "$output" ]; then
            rm -f "$output"
          fi
        done

        if [ ! -e "$config_dir/hypr/hyprland/colors.conf" ]; then
          cp "${source "hypr/hyprland/colors.conf"}" "$config_dir/hypr/hyprland/colors.conf"
        fi
        if [ ! -e "$config_dir/hypr/hyprlock.conf" ]; then
          cp "${source "hypr/hyprlock.conf"}" "$config_dir/hypr/hyprlock.conf"
        fi
        if [ ! -e "$config_dir/fuzzel/fuzzel_theme.ini" ]; then
          cp "${source "fuzzel/fuzzel_theme.ini"}" "$config_dir/fuzzel/fuzzel_theme.ini"
        fi
        if [ ! -e "$config_dir/gtk-3.0/gtk.css" ]; then
          cp "${source "matugen/templates/gtk/gtk-colors.css"}" "$config_dir/gtk-3.0/gtk.css"
        fi
        if [ ! -e "$config_dir/gtk-4.0/gtk.css" ]; then
          cp "${source "matugen/templates/gtk/gtk-colors.css"}" "$config_dir/gtk-4.0/gtk.css"
        fi
      '';
    in
    {
      gtk = {
        enable = true;
        iconTheme = {
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
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
        "quickshell/translations".source = source "quickshell/translations";
        "hypr/hyprland/env.conf".text = builtins.replaceStrings
          [
            "env = ILLOGICAL_IMPULSE_VIRTUAL_ENV, ~/.local/state/quickshell/.venv"
            "env = TERMINAL,kitty -1"
          ]
          [
            "env = ILLOGICAL_IMPULSE_VIRTUAL_ENV, ${config.xdg.stateHome}/quickshell/.venv"
            "env = TERMINAL,wezterm"
          ]
          (builtins.readFile (source "hypr/hyprland/env.conf"));
        "hypr/hyprland/execs.conf".text = builtins.replaceStrings
          [
            "exec-once = hypridle"
            "/usr/lib/polkit-kde-authentication-agent-1 || /usr/libexec/polkit-kde-authentication-agent-1  || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/libexec/polkit-gnome/polkit-gnome-authentication-agent-1"
          ]
          [
            ""
            "exec-once = ${polkitAgent}"
          ]
          (builtins.readFile (source "hypr/hyprland/execs.conf"));
        "hypr/hyprland/general.conf".source = source "hypr/hyprland/general.conf";
        "hypr/hyprland/keybinds.conf".source = source "hypr/hyprland/keybinds.conf";
        "hypr/hyprland/rules.conf".source = source "hypr/hyprland/rules.conf";
        "hypr/hyprland/scripts".source = hyprScripts;
        "hypr/hyprlock".source = source "hypr/hyprlock";
        "hypr/shaders".source = source "hypr/shaders";
        "fuzzel/fuzzel.ini".source = source "fuzzel/fuzzel.ini";
        "matugen/templates/colors.json".source = source "matugen/templates/colors.json";
        "matugen/templates/fuzzel/fuzzel_theme.ini".source = source "matugen/templates/fuzzel/fuzzel_theme.ini";
        "matugen/templates/gtk/gtk-colors.css".source = source "matugen/templates/gtk/gtk-colors.css";
        "matugen/templates/hyprland/colors.conf".source = source "matugen/templates/hyprland/colors.conf";
        "matugen/templates/hyprland/hyprlock.conf".source = source "matugen/templates/hyprland/hyprlock.conf";
        "matugen/templates/kde/color.txt".source = source "matugen/templates/kde/color.txt";
        "matugen/templates/wallpaper.txt".source = source "matugen/templates/wallpaper.txt";
        "wlogout/layout".source = source "wlogout/layout";
        "wlogout/style.css".source = source "wlogout/style.css";
      };

      home.activation.seedEnd4Runtime = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${seedRuntime}
      '';
    };
  };
}
