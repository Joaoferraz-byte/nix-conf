{ config, inputs, pkgs, desktopProfile ? { }, userName ? "livara", ... }:
{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./appimage.nix
    ./applications.nix
    ./session.nix
    ./niri.nix
    (import ./monitors.nix { monitorProfile = desktopProfile.monitorProfile or "myMachine"; })
    ./themes.nix
    ./sync.nix
  ];

  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "26.11";
  programs.home-manager.enable = true;
  services.easyeffects.enable = true;

  home.file.".face.icon".source = builtins.path {
    path = ../../Icons/6afde16e1ef1cb3257b30e01890787dd.jpg;
    name = "livara-profile-icon";
  };
  home.file."Fire/.keep".text = "";

  programs.livara.visual = {
    enable = true;
    wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
    themeName = "Livara";
    noctaliaPackage = inputs.noctalia.packages.${pkgs.system}.default;
    wallpaperAutomationEnabled = false;
    weatherEnabled = true;
    weatherAddress = "Rua João da Cunha, Jardim João XXIII, São Paulo, SP, Brasil";
    systemMonitorEnabled = true;
    controlCenterHiddenTabs = [ "bluetooth" "calendar" ];
    controlCenterShortcuts = [
      "audio"
      "system"
      "weather"
      "keyboard_layout"
      "livara/productivity:tasks"
      "livara/productivity:tablet"
    ];
    barMainStartWidgets = [ "launcher" "wallpaper" "workspaces" ];
    barMainCenterWidgets = [ "clock" "weather" ];
    barMainEndWidgets = [ "media" "tray" "notifications" "clipboard" "network" "volume" "brightness" "livara/productivity:tablet" "control-center" "session" ];
  };

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projetos";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };
}
