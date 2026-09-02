{ config, inputs, lib, pkgs, desktopProfile ? { }, userName ? "livara", ... }:
  let
  booksDirectory = "${config.home.homeDirectory}/Books";
  gamesDirectory = "${config.home.homeDirectory}/Games";
  musicsDirectory = "${config.home.homeDirectory}/Musics";
  templatesDirectory = "${config.home.homeDirectory}/Templates";
  normalizeNoctaliaThemeOverride = pkgs.writeShellApplication {
    name = "noctalia-normalize-theme-override";
    runtimeInputs = with pkgs; [ bash coreutils gnugrep gnused ];
    text = ''
      set -Eeuo pipefail
      state_file="''${NOCTALIA_STATE_HOME:-''${XDG_STATE_HOME:-$HOME/.local/state}}/noctalia/settings.toml"
      [[ -f "$state_file" ]] || exit 0

      # GUI settings are mutable app-owned state and load after config.toml.
      # Remove only the stale value reported by the user; leave all other GUI
      # preferences and any future deliberate scheme choice untouched.
      if ! grep -qE '^[[:space:]]*wallpaper_scheme[[:space:]]*=[[:space:]]*"vibrant"[[:space:]]*$' "$state_file"; then
        exit 0
      fi

      tmp="$(mktemp "$(dirname "$state_file")/.settings.toml.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT
      sed '/^[[:space:]]*wallpaper_scheme[[:space:]]*=[[:space:]]*"vibrant"[[:space:]]*$/d' "$state_file" > "$tmp"
      if [[ -L "$state_file" ]]; then
        # Preserve a user-provided symlink, as Noctalia itself does.
        cat "$tmp" > "$state_file"
      else
        chmod --reference="$state_file" "$tmp" 2>/dev/null || true
        mv -f "$tmp" "$state_file"
      fi
      printf '%s\n' 'Removed stale Noctalia wallpaper scheme override: vibrant'
    '';
  };
  initBooks = pkgs.writeShellApplication {
    name = "livara-init-books";
    runtimeInputs = with pkgs; [ bash coreutils findutils git ];
    text = ''
      set -Eeuo pipefail
      export GIT_TERMINAL_PROMPT=0
      directory="${booksDirectory}"
      repository="https://github.com/Joaoferraz-byte/Books.git"
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
      git clone "$repository" "$tmp"
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
    mkdir -p "${booksDirectory}" "${gamesDirectory}" \
      "${musicsDirectory}" "${templatesDirectory}" \
      "${config.home.homeDirectory}/Fire" \
      "${config.home.homeDirectory}/Projects"
  '';

  home.activation.normalizeNoctaliaThemeOverride = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD "${normalizeNoctaliaThemeOverride}/bin/noctalia-normalize-theme-override"
  '';

  home.packages = [ initBooks normalizeNoctaliaThemeOverride ];

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
