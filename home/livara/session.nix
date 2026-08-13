{ config, pkgs, lib, ... }:
let
  home = config.home.homeDirectory;
  randomWallpaper = pkgs.writeShellScript "end4-wallpaper-random-on-login" ''
    set -eu
    wallpapers_dir="${home}/Pictures/Wallpapers"
    wallpaper="$(${pkgs.findutils}/bin/find "$wallpapers_dir" -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
      -print 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n 1)"
    if [ -z "$wallpaper" ]; then
      exit 0
    fi
    ${pkgs.coreutils}/bin/sleep 2
    exec "${home}/.config/quickshell/ii/scripts/colors/switchwall.sh" --image "$wallpaper"
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    xwayland.enable = true;
    settings = {
      "$qsConfig" = "ii";
      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Classic"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "QT_QPA_PLATFORM,wayland;xcb"
        "TERMINAL,wezterm"
      ];
      input = {
        kb_layout = "br";
        touchpad = {
          tap-to-click = true;
          disable_while_typing = true;
          natural_scroll = true;
        };
      };
    };
    extraConfig = ''
      source=~/.config/hypr/hyprland/env.conf
      source=~/.config/hypr/hyprland/execs.conf
      source=~/.config/hypr/hyprland/general.conf
      source=~/.config/hypr/hyprland/rules.conf
      source=~/.config/hypr/hyprland/colors.conf
      source=~/.config/hypr/hyprland/keybinds.conf
      source=~/.config/hypr/nix-conf.conf
    '';
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend || loginctl suspend";
        }
      ];
    };
  };

  xdg.configFile."hypr/nix-conf.conf".text = ''
    $mod = SUPER

    # QuickShell compatibility
    unbind = $mod, Comma
    unbind = $mod, Space
    unbind = $mod, X
    unbind = $mod, D
    unbind = $mod, V
    unbind = $mod, N
    unbind = $mod, Tab
    unbind = $mod, W
    unbind = $mod, E
    unbind = $mod, O
    unbind = $mod, T
    unbind = $mod, Return
    unbind = $mod, C
    unbind = $mod, S
    unbind = $mod CTRL, S
    unbind = $mod SHIFT, S
    unbind = $mod SHIFT, W
    unbind = $mod, F
    unbind = $mod SHIFT, F
    bind = $mod, Comma, exec, qs -p ~/.config/quickshell/$qsConfig/settings.qml
    bind = $mod, Space, exec, qs -c $qsConfig ipc call overviewToggle
    bind = $mod, X, exec, qs -c $qsConfig ipc call sessionToggle
    bind = $mod, D, exec, qs -c $qsConfig ipc call overviewToggle
    bind = $mod, V, exec, qs -c $qsConfig ipc call overviewClipboardToggle
    bind = $mod, N, exec, zennotes
    bind = $mod, Tab, exec, qs -c $qsConfig ipc call cheatsheetToggle

    # Applications
    bind = $mod, W, exec, zen-beta
    bind = $mod, E, exec, nautilus
    bind = $mod, O, exec, zennotes
    bind = $mod, T, exec, wezterm
    bind = $mod, Return, exec, wezterm
    bind = $mod, C, killactive

    # Window navigation
    bind = $mod, Left, movefocus, l
    bind = $mod, Right, movefocus, r
    bind = $mod, Up, movefocus, u
    bind = $mod, Down, movefocus, d
    bind = $mod, F, fullscreen, 0
    bind = $mod SHIFT, F, fullscreen, 1

    # Screenshots
    bind = $mod SHIFT, S, exec, grim -g "$(slurp)" - | satty --filename - --copy-command wl-copy --early-exit
    bind = $mod, S, exec, grimblast --notify copy output
    bind = $mod CTRL, S, exec, grimblast --notify copy active
    bind = , Print, exec, grimblast --notify copy output
    bind = CTRL, Print, exec, mkdir -p "$HOME/Pictures/Screenshots" && grimblast --notify copysave output

    # Clipboard, color and wallpaper
    bind = $mod SHIFT, C, exec, hyprpicker -a
    bind = $mod SHIFT, W, exec, ~/.config/quickshell/$qsConfig/scripts/colors/switchwall.sh
    bind = $mod CTRL SHIFT, W, exec, ~/.config/quickshell/$qsConfig/scripts/colors/switchwall.sh
  '';

  home.activation.setupScreenshots = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${home}/Pictures/Screenshots"
  '';

  systemd.user.services.end4-wallpaper-random-on-login = {
    Unit = {
      Description = "Select a random end-4 wallpaper at graphical session start";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = randomWallpaper;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
