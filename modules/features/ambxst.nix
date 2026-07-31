# Applications: terminal, launcher, control panels
{ pkgs }:

with pkgs; [
  # Terminal
  kitty
  tmux

  # Launcher
  fuzzel

  # Control panels
  networkmanagerapplet
  blueman
  pavucontrol
  easyeffects
  gradia

  # Icons
  kora-icon-theme
  hicolor-icon-theme
]
