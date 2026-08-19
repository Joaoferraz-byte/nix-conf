{ config, desktopProfile ? { }, pkgs, ... }:

let
  home = config.home.homeDirectory;
  keyboardLayout = desktopProfile.keyboardLayout or "br";
  keyboardVariant = desktopProfile.keyboardVariant or "abnt2";
  workspaceFocus = pkgs.writeShellApplication {
    name = "niri-focus-workspace";
    runtimeInputs = [ pkgs.jq pkgs.niri ];
    text = ''
      set -Eeuo pipefail
      target="''${1:?workspace index is required}"
      [[ "$target" =~ ^[1-9][0-9]*$ ]] || exit 2
      if niri msg --json workspaces | jq -e --argjson target "$target" 'any(.[]; .idx == $target)' >/dev/null; then
        niri msg action focus-workspace "$target"
      fi
    '';
  };
in
{
  home.packages = [ workspaceFocus ];

  home.file.".config/niri/config.kdl".text = ''
    // niri is the sole compositor owner. No visual shell or wallpaper daemon
    // is started here; Noctalia owns the shell and its documented IPC.
    include "outputs.kdl"

    input {
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
      default-column-width { proportion 0.50; }
      preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
      }
    }

    prefer-no-csd

    window-rule {
      geometry-corner-radius 12
      clip-to-geometry true
    }

    binds {
      Mod+Return repeat=false { spawn "wezterm" "start" "--cwd" "${home}"; }
      Mod+Space repeat=false { spawn-sh "noctalia msg panel-toggle launcher"; }
      Mod+W repeat=false { spawn "${home}/.local/share/livara/scripts/open-zen.sh"; }
      Mod+Alt+W repeat=false { spawn "${home}/.local/share/livara/scripts/open-zen.sh"; }
      Mod+E repeat=false { spawn "nautilus" "--new-window"; }
      Mod+F repeat=false { fullscreen-window; }
      Mod+F11 repeat=false { fullscreen-window; }
      Mod+Q repeat=false { close-window; }
      Mod+Shift+Q repeat=false { close-window; }
      Mod+Shift+W repeat=false { spawn-sh "noctalia msg panel-toggle wallpaper"; }
      Mod+Shift+S repeat=false { screenshot; }
      Mod+Shift+Slash repeat=false { show-hotkey-overlay; }
      Mod+S repeat=false { spawn-sh "noctalia msg panel-toggle control-center"; }
      Mod+C repeat=false { spawn-sh "noctalia msg panel-toggle clipboard"; }
      Mod+N repeat=false { spawn-sh "noctalia msg panel-toggle control-center network"; }
      Mod+V repeat=false { spawn-sh "noctalia msg panel-toggle control-center volume"; }
      Mod+Alt+M repeat=false { spawn-sh "noctalia msg panel-toggle control-center media"; }
      Mod+Alt+H repeat=false { spawn "${home}/.local/share/livara/scripts/open-nixos-nvim.sh"; }

      Mod+Left { focus-column-left; }
      Mod+Down { focus-window-down; }
      Mod+Up { focus-window-up; }
      Mod+Right { focus-column-right; }
      Mod+H { focus-column-left; }
      Mod+J { focus-window-down; }
      Mod+K { focus-window-up; }
      Mod+L { focus-column-right; }
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

      Mod+1 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "1"; }
      Mod+2 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "2"; }
      Mod+3 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "3"; }
      Mod+4 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "4"; }
      Mod+5 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "5"; }
      Mod+6 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "6"; }
      Mod+7 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "7"; }
      Mod+8 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "8"; }
      Mod+9 { spawn "${workspaceFocus}/bin/niri-focus-workspace" "9"; }
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
      Mod+Shift+R { switch-preset-column-width-back; }
      Mod+Ctrl+Shift+R { switch-preset-window-height; }
      Mod+Ctrl+R { reset-window-height; }
      Mod+Shift+F { maximize-column; }
      Mod+Shift+M { maximize-window-to-edges; }
      Mod+Ctrl+F { expand-column-to-available-width; }
      Mod+Shift+C { center-column; }
      Mod+Ctrl+Shift+C { center-visible-columns; }
      Mod+Minus { set-column-width "-10%"; }
      Mod+Equal { set-column-width "+10%"; }
      Mod+Shift+Minus { set-window-height "-10%"; }
      Mod+Shift+Equal { set-window-height "+10%"; }
      Mod+Shift+V { toggle-window-floating; }
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

    spawn-at-startup "systemctl" "--user" "start" "--no-block" "livara-theme-sync.service"
  '';
}
