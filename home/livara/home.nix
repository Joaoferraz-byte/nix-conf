{ config, inputs, hostName ? "unknown", userName ? "livara", ... }:
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
    hostProfile = if hostName == "latitude" then "laptop" else "desktop";
    networkWidgets = true;
    bluetoothWidgets = hostName == "latitude";
    wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
  };

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projetos";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };
}
