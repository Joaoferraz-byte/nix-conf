{ config, inputs, lib, pkgs, desktopProfile ? { }, userName ? "livara", ... }:
  let
  booksDirectory = "${config.home.homeDirectory}/Books";
  gamesDirectory = "${config.home.homeDirectory}/Games";
  musicsDirectory = "${config.home.homeDirectory}/Musics";
  templatesDirectory = "${config.home.homeDirectory}/Templates";
  initBooks = pkgs.writeShellApplication {
    name = "livara-init-books";
    runtimeInputs = with pkgs; [ bash coreutils findutils git ];
    text = ''
      set -Eeuo pipefail
      export GIT_TERMINAL_PROMPT=0
      directory="${booksDirectory}"
      repository="https://github.com/Joaoferraz-byte/Books.git"
      revision="c6003b42654dae65d5d3e2a7d68d7cab8b573dea"
      mkdir -p "$(dirname "$directory")"
      if [[ -d "$directory/.git" ]]; then
        printf 'Books repository already exists at %s\n' "$directory"
        exit 0
      fi
      if [[ -n "$(find "$directory" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
        printf 'Refusing to clone Books over a non-empty directory: %s\n' "$directory" >&2
        exit 1
      fi
      tmp="''${directory}.tmp.$$"
      rm -rf "$tmp"
      trap 'rm -rf "$tmp"' EXIT
      git clone --depth 1 "$repository" "$tmp"
      if ! git -C "$tmp" checkout --detach "$revision"; then
        git -C "$tmp" fetch --depth 1 origin "$revision"
        git -C "$tmp" checkout --detach "$revision"
      fi
      mv -- "$tmp" "$directory"
      trap - EXIT
    '';
  };
in
{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./appimage.nix
    ./applications.nix
    ./session.nix
    ./niri.nix
    (import ./monitors.nix { monitorProfile = desktopProfile.monitorProfile or "myMachine"; })
    ./stylix.nix
    ./themes.nix
    ./sync.nix
  ];

  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "26.11";
  programs.home-manager.enable = true;


  # EasyEffects: keep as application but don't auto-start the service.
  services.easyeffects.enable = false;
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };

  # NoDisplay .desktop override ensures EasyEffects never appears in the launcher
  # even if an application launcher ignores user-state filters.
  xdg.dataFile."applications/com.github.wwmm.easyeffects.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=EasyEffects
    Comment=Audio effect processor
    Icon=com.github.wwmm.easyeffects
    Exec=easyeffects
    Categories=AudioVideo;Audio;
    NoDisplay=true
  '';

  # Profile icon for AccountsService and greeter profile cards.
  home.file.".face" = {
    source = ./assets/livara-profile-icon.jpg;
    force = true;
  };

  home.activation.livaraDataDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${booksDirectory}" "${gamesDirectory}" \
      "${musicsDirectory}" "${templatesDirectory}" \
      "${config.home.homeDirectory}/Fire" \
      "${config.home.homeDirectory}/Projects"
  '';

  home.packages = [ initBooks ];

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
    BOOKS_DIR = booksDirectory;
    GAMES_DIR = gamesDirectory;
    MUSICS_DIR = musicsDirectory;
    TEMPLATES_DIR = templatesDirectory;
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };
}
