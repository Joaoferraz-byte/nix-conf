{ config, inputs, hostName ? "unknown", userName ? "livara", compositor ? "hyprland", ... }:
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
    (import ./monitors.nix { inherit hostName; })
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
    hostProfile = if hostName == "latitude" then "laptop" else "desktop";
    networkWidgets = true;
    bluetoothWidgets = hostName == "latitude";
    wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
    keyboardLayout = if hostName == "latitude" then "ie" else "br";
    keyboardVariant = if hostName == "latitude" then "" else "abnt2";
    internalKeyboardDevice = if hostName == "latitude" then "at-translated-set-2-keyboard" else "";
    externalKeyboardDevices = if hostName == "latitude" then [
      "jp-usb-keyboard"
      "jp-usb-keyboard-1"
      "keyd-virtual-keyboard"
    ] else [ ];
    externalKeyboardLayout = "br";
    externalKeyboardVariant = "abnt2";
  };

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projetos";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };
}
