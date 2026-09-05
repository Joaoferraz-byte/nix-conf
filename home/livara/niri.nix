{ config, lib, pkgs, desktopProfile ? { }, ... }:
let
  home = config.home.homeDirectory;
  keyboardLayout = desktopProfile.keyboardLayout or "br";
  keyboardVariant = desktopProfile.keyboardVariant or "abnt2";
  startNoctalia = pkgs.writeShellApplication {
    name = "livara-start-noctalia";
    runtimeInputs = with pkgs; [ bash coreutils ];
    text = ''
      set -u
      noctalia &
      wait "$!"
    '';
  };
in
{
  home.packages = [ startNoctalia ];

  # Home Manager may replace the store-backed config symlink atomically; ask the
  # running compositor to load the new file without requiring a new login.
  home.activation.reloadNiriConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if command -v niri >/dev/null 2>&1; then
      $DRY_RUN_CMD niri msg action load-config-file --path "${home}/.config/niri/config.kdl" || true
    fi
  '';

  home.file.".config/niri/config.kdl".text = ''
    // Niri owns compositor policy; Noctalia owns only shell surfaces and IPC.
    include "outputs.kdl"
    cursor {
      // Stylix owns the cursor package/name/size; Niri applies it to the compositor.
      xcursor-theme "${config.stylix.cursor.name}"
      xcursor-size ${toString config.stylix.cursor.size}
    }

    input {
      mod-key "Super"
      keyboard {
        xkb {
          layout "${keyboardLayout}"
          variant "${keyboardVariant}"
          model "pc105"
          rules "evdev"
          options ""
        }
        numlock
      }
      focus-follows-mouse
      warp-mouse-to-focus
    }

    layout {
      gaps 8
      center-focused-column "never"
      default-column-width { proportion 0.5; }
      focus-ring {
        on
        width 1.4
      }
      border {
        on
        width 1.4
      }
      preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
      }
    }

    blur {
      passes 2
      offset 3.0
      noise 0.03
      saturation 1.0
    }

    hotkey-overlay { skip-at-startup; }

    environment {
      GTK_ICON_THEME "Livara-Kora"
      QT_ICON_THEME "Livara-Kora"
      // Make the Home Manager cursor package discoverable to Niri and clients.
      XCURSOR_PATH "${config.home.profileDirectory}/share/icons:${home}/.local/share/icons:${home}/.icons"
      // Noctalia's Qt template targets qt6ct; keep this single owner in Niri.
      QT_QPA_PLATFORMTHEME "qt6ct"
      MOZ_ENABLE_WAYLAND "1"
      NIXOS_OZONE_WL "1"
    }

    // Noctalia layer surfaces use their own moderate blur and do not inherit
    // the application opacity policy below.
    layer-rule {
      match namespace="^noctalia-backdrop*"
      place-within-backdrop false
    }
    layer-rule {
      match namespace="^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$"
      background-effect {
        xray false
        blur true
      }
    }
    layer-rule {
      match namespace="^noctalia-window-switcher$"
      background-effect {
        xray false
        blur true
      }
    }

    window-rule {
      geometry-corner-radius 12
      clip-to-geometry true
    }

    window-rule {
      match app-id=r#"^org\.wezfurlong\.wezterm$"#
      default-column-width { proportion 0.5; }
      default-window-height { proportion 1.0; }
      open-fullscreen false
    }

    window-rule {
      match app-id=r#"^com\.github\.xournalpp\.xournalpp$"#
      default-column-width { proportion 1.0; }
      default-window-height { proportion 1.0; }
      open-maximized-to-edges true
      open-fullscreen false
      geometry-corner-radius 0
      clip-to-geometry false
    }

    // Keep Niri's native automatic floating for parented dialogs, password
    // prompts and fixed-size utility windows. Normal application windows,
    // including browser main windows, remain tiled by their normal geometry.

    window-rule {
      // Keep inactive windows nearly opaque while leaving enough alpha for the
      // compositor to show the focused glass treatment without washed-out text.
      opacity 0.96
      draw-border-with-background false
    }
    window-rule {
      match is-focused=true
      opacity 0.84
      background-effect {
        // Xray blur is the reliable Niri 26.04 path across GPU/output setups.
        // Non-xray blur remains experimental and can disappear on NVIDIA paths.
        xray true
        blur true
        noise 0.03
        saturation 1.0
      }
    }
    window-rule {
      match is-focused=false
      background-effect {
        blur false
      }
    }

    binds {
      // Noctalia v5 surfaces and shell actions.
      Mod+Return repeat=false { spawn "wezterm" "start" "--always-new-process" "--cwd" "${home}"; }
      Mod+Space repeat=false { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
      Mod+W repeat=false { spawn "${home}/.local/share/livara/scripts/open-zen.sh"; }
      Mod+Alt+W repeat=false { spawn "${home}/.local/share/livara/scripts/open-zen.sh"; }
      Mod+E repeat=false { spawn "nautilus" "--new-window"; }
      Mod+D repeat=false { spawn "livara-study-planner" "gui"; }
      Mod+N repeat=false { spawn "${home}/.local/share/livara/scripts/open-nixos-nvim.sh"; }
      Mod+F repeat=false { fullscreen-window; }
      Mod+F11 repeat=false { fullscreen-window; }
      Mod+Q repeat=false { close-window; }
      Mod+Shift+Q repeat=false { close-window; }
      Mod+Shift+W repeat=false { spawn "noctalia" "msg" "panel-toggle" "wallpaper"; }
      // Noctalia owns the modern wlr-screencopy flow: region selection, freeze,
      // remembered region, clipboard and file output are configured in its shell policy.
      Mod+Shift+S repeat=false { spawn "noctalia" "msg" "screenshot-region"; }
      // Screen Toolkit is a separate on-demand panel for annotation, OCR, QR,
      // palette extraction, measurement and recording; it is not a bar widget.
      Mod+Shift+P repeat=false { spawn "noctalia" "msg" "plugin" "alexander/screen-toolkit:service" "all" "toggle"; }
      // These panels remain shortcut-only, as requested, and do not occupy bar space.
      Mod+G repeat=false { spawn "noctalia" "msg" "panel-toggle" "nomadcxx/gamer-mode:main"; }
      Mod+S repeat=false { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
      Mod+C repeat=false { spawn "noctalia" "msg" "panel-toggle" "clipboard"; }
      Mod+V repeat=false { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
      Mod+Alt+M repeat=false { spawn "noctalia" "msg" "panel-toggle" "control-center" "media"; }
      Mod+Alt+H repeat=false { spawn "${home}/.local/share/livara/scripts/open-nixos-nvim.sh"; }
      Mod+Alt+L repeat=false { spawn "noctalia" "msg" "session" "lock"; }
      // Direct GPU Screen Recorder adapters; the second press sends SIGINT
      // and lets the same process finalize the video file.
      Mod+Shift+R repeat=false { spawn "${home}/.local/share/livara/scripts/toggle-screen-recording.sh"; }
      Mod+Ctrl+Shift+R repeat=false { spawn "${home}/.local/share/livara/scripts/toggle-screen-recording-silent.sh"; }

      Mod+Left { focus-column-left; }
      Mod+Down { focus-window-down; }
      Mod+Up { focus-window-up; }
      Mod+Right { focus-column-right; }
      Mod+H { focus-column-left; }
      Mod+J { focus-window-down; }
      Mod+K { focus-window-up; }
      Mod+L { focus-column-right; }
      Mod+WheelScrollDown cooldown-ms=150 { focus-window-down; }
      Mod+WheelScrollUp cooldown-ms=150 { focus-window-up; }
      Mod+WheelScrollRight cooldown-ms=150 { focus-column-right; }
      Mod+WheelScrollLeft cooldown-ms=150 { focus-column-left; }

      Mod+Home { focus-column-first; }
      Mod+End { focus-column-last; }

      Mod+Ctrl+Left { move-column-left; }
      Mod+Ctrl+Down { move-window-down; }
      Mod+Ctrl+Up { move-window-up; }
      Mod+Ctrl+Right { move-column-right; }
      Mod+Ctrl+H { move-column-left; }
      Mod+Ctrl+J { move-window-down; }
      Mod+Ctrl+K { move-window-up; }
      Mod+Ctrl+L { move-column-right; }
      Mod+Ctrl+Home { move-column-to-first; }
      Mod+Ctrl+End { move-column-to-last; }

      Mod+Shift+Left { focus-monitor-left; }
      Mod+Shift+Down { focus-monitor-down; }
      Mod+Shift+Up { focus-monitor-up; }
      Mod+Shift+Right { focus-monitor-right; }
      Mod+Shift+H { focus-monitor-left; }
      Mod+Shift+J { focus-monitor-down; }
      Mod+Shift+K { focus-monitor-up; }
      Mod+Shift+L { focus-monitor-right; }
      Mod+Ctrl+Shift+Left { move-column-to-monitor-left; }
      Mod+Ctrl+Shift+Down { move-column-to-monitor-down; }
      Mod+Ctrl+Shift+Up { move-column-to-monitor-up; }
      Mod+Ctrl+Shift+Right { move-column-to-monitor-right; }

      Mod+1 { focus-workspace 1; }
      Mod+2 { focus-workspace 2; }
      Mod+3 { focus-workspace 3; }
      Mod+4 { focus-workspace 4; }
      Mod+5 { focus-workspace 5; }
      Mod+6 { focus-workspace 6; }
      Mod+7 { focus-workspace 7; }
      Mod+8 { focus-workspace 8; }
      Mod+9 { focus-workspace 9; }
      Mod+Page_Down { focus-workspace-down; }
      Mod+Page_Up { focus-workspace-up; }
      Mod+U { focus-workspace-down; }
      Mod+I { focus-workspace-up; }
      Mod+Ctrl+1 { move-column-to-workspace 1; }
      Mod+Ctrl+2 { move-column-to-workspace 2; }
      Mod+Ctrl+3 { move-column-to-workspace 3; }
      Mod+Ctrl+4 { move-column-to-workspace 4; }
      Mod+Ctrl+5 { move-column-to-workspace 5; }
      Mod+Ctrl+6 { move-column-to-workspace 6; }
      Mod+Ctrl+7 { move-column-to-workspace 7; }
      Mod+Ctrl+8 { move-column-to-workspace 8; }
      Mod+Ctrl+9 { move-column-to-workspace 9; }
      Mod+Tab repeat=false { focus-workspace-previous; }

      Mod+BracketLeft { consume-or-expel-window-left; }
      Mod+BracketRight { consume-or-expel-window-right; }
      Mod+Comma { consume-window-into-column; }
      Mod+Period { expel-window-from-column; }
      Mod+R { switch-preset-column-width; }
      // Reassigned because Mod+Ctrl+Shift+R is the silent recorder toggle.
      Mod+Alt+Shift+R { switch-preset-window-height; }
      Mod+Ctrl+R { reset-window-height; }
      Mod+Shift+F { maximize-column; }
      Mod+Shift+M { maximize-window-to-edges; }
      Mod+Ctrl+F { toggle-window-floating; }
      Mod+Shift+C repeat=false { spawn "sh" "-c" "hyprpicker -f hex | wl-copy"; }
      Mod+Ctrl+Shift+C { center-visible-columns; }
      Mod+Minus { set-column-width "-10%"; }
      Mod+Equal { set-column-width "+10%"; }
      Mod+Shift+Minus { set-window-height "-10%"; }
      Mod+Shift+Equal { set-window-height "+10%"; }
      Mod+Ctrl+W { toggle-column-tabbed-display; }
      Mod+O repeat=false { toggle-overview; }
      Mod+Escape repeat=false { toggle-keyboard-shortcuts-inhibit; }

      XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
      XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }
      XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
      XF86AudioPause allow-when-locked=true { spawn "playerctl" "play-pause"; }
      XF86AudioStop allow-when-locked=true { spawn "playerctl" "stop"; }
      XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
      XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
    }

    // Exactly one shell instance, inheriting the niri Wayland/D-Bus session.
    // The short delay avoids the documented Niri startup race where the bar
    // renders but Noctalia's IPC/event loop is not yet responsive. The
    spawn-at-startup "${startNoctalia}/bin/livara-start-noctalia"

    // Noctalia renders wallpaper-derived colors and Niri watches this include.
    include optional=true "noctalia.kdl"
  '';
}
