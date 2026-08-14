{ config, inputs, userName ? "livara", ... }:
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
    ./themes.nix
    ./sync.nix
  ];

  # Identity
  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "26.11";
  programs.home-manager.enable = true;
  home.file.".face.icon".source = profileIcon;
  home.file.".local/bin/sync-end4-state".source = ../../scripts/sync-end4-state.sh;
  home.file."Fire/.keep".text = "";

  # Environment
  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projetos";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };
}
