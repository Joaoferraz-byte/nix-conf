{ config, inputs, desktopProfile ? { }, userName ? "livara", compositor ? "hyprland", ... }:
let
  iconsPath = builtins.path {
    path = ../../Icons;
    name = "nix-conf-icons";
  };
  profileIcon = iconsPath + "/6afde16e1ef1cb3257b30e01890787dd.jpg";
in
{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./appimage.nix
    ./applications.nix
    ./session.nix
    (import ./monitors.nix { monitorProfile = desktopProfile.monitorProfile or "myMachine"; })
    ./themes.nix
    ./sync.nix
  ];

  # Identity
  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "26.11";
  programs.home-manager.enable = true;
  services.easyeffects.enable = true;
  home.file.".face.icon".source = profileIcon;
  home.file."Fire/.keep".text = "";

  # Environment
  programs.serpantinum = {
    enable = true;
    inherit compositor;
    hostProfile = desktopProfile.shellProfile or "desktop";
    powerWidgetVariant = desktopProfile.powerWidgetVariant or "battery";
    tabletWidget = desktopProfile.tabletWidget or false;
    networkWidgets = desktopProfile.networkWidgets or true;
    bluetoothWidgets = desktopProfile.bluetoothWidgets or false;
    wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
    keyboardLayout = desktopProfile.keyboardLayout or "br";
    keyboardVariant = desktopProfile.keyboardVariant or "abnt2";
    internalKeyboardDevice = desktopProfile.internalKeyboardDevice or "";
    externalKeyboardDevices = desktopProfile.externalKeyboardDevices or [ ];
    externalKeyboardLayout = desktopProfile.externalKeyboardLayout or "br";
    externalKeyboardVariant = desktopProfile.externalKeyboardVariant or "abnt2";
  };

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projetos";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };
}
