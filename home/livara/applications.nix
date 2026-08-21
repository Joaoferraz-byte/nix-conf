{ config, pkgs, lib, inputs, self, ... }:
let
  xournalppLocalConfig = "${config.home.homeDirectory}/.config/xournalpp";
  xournalppLegacyConfig = "${config.home.homeDirectory}/.config/nixos/xournalpp";
  xournalppSettings = pkgs.writeText "xournalpp-settings.xml" (builtins.replaceStrings
    [ "/home/livara/.config/xournalpp" "tokyo-night.gpl" ]
    [ "${config.home.homeDirectory}/.config/xournalpp" "livara.gpl" ]
    (builtins.readFile "${inputs.xournal-conf}/xournalpp/settings.xml"));
  xournalppToolbar = pkgs.writeText "xournalpp-toolbar.ini" (builtins.replaceStrings
    [ "toolbarTop1=PEN,ERASER,HIGHLIGHTER" ]
    [ "toolbarTop1=HIGHLIGHTER,ERASER,PEN" ]
    (builtins.readFile "${inputs.xournal-conf}/xournalpp/toolbar.ini"));
  # Keep the expressive icon choice local to Nautilus. GTK's global session
  # remains Kora for DMS and other applications; this wrapper only overrides
  # the environment of the Files process.
  nautilusLivara = pkgs.writeShellScriptBin "nautilus-livara" ''
    exec env GTK_ICON_THEME=Papirus-Dark ${pkgs.nautilus}/bin/nautilus "$@"
  '';
in
{
  # Applications
  programs.nixvim = {
    enable = true;
    imports = [ inputs.vim-conf.lib.nixvimModule ];
  };

  programs.zen-browser = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
    };
  };

  programs.firefox = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
    };
    profiles.default = {
      id = 0;
      isDefault = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layout.css.prefers-color-scheme.content-override" = 2;
        "svg.context-properties.content.enabled" = true;
        "userChrome.theme-material" = true;
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "cd ~/.config/nixos && ./install.sh";
    };
    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "robbyrussell";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    git
    xournalpp
    affinity-v3
    easyeffects
    nautilusLivara
    papirus-icon-theme
  ];

  home.activation.xournalppLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${xournalppLocalConfig}"
    for file in settings.xml toolbar.ini; do
      native="${xournalppLocalConfig}/$file"
      legacy="${xournalppLegacyConfig}/$file"
      if [ -L "$native" ] && [ -e "$legacy" ]; then
        $DRY_RUN_CMD cp -L "$legacy" "$native.migrate"
        $DRY_RUN_CMD mv -f "$native.migrate" "$native"
      elif [ ! -e "$native" ] && [ -e "$legacy" ]; then
        $DRY_RUN_CMD cp -L "$legacy" "$native"
      fi
    done
    if [ -f "${xournalppLocalConfig}/settings.xml" ]; then
      $DRY_RUN_CMD sed -i 's/tokyo-night\.gpl/livara.gpl/g' "${xournalppLocalConfig}/settings.xml"
    elif [ ! -e "${xournalppLocalConfig}/settings.xml" ]; then
      $DRY_RUN_CMD cp "${xournalppSettings}" "${xournalppLocalConfig}/settings.xml"
    fi
    if [ ! -e "${xournalppLocalConfig}/toolbar.ini" ]; then
      $DRY_RUN_CMD cp "${xournalppToolbar}" "${xournalppLocalConfig}/toolbar.ini"
    fi
  '';
  xdg.configFile."xournalpp/default_template.tex".source = "${inputs.xournal-conf}/xournalpp/default_template.tex";

  # Override the packaged Nautilus desktop entry at the user-priority XDG
  # location. DBusActivatable=false is intentional: otherwise a desktop
  # environment may bypass the wrapper and start the unmodified process.
  home.file.".local/share/applications/org.gnome.Nautilus.desktop".text = ''
    [Desktop Entry]
    Name=Files
    Comment=Access and organize files
    Exec=${nautilusLivara}/bin/nautilus-livara --new-window %U
    Icon=org.gnome.Nautilus
    Terminal=false
    Type=Application
    StartupNotify=true
    DBusActivatable=false
    Categories=GNOME;GTK;Utility;Core;FileManager;
    MimeType=inode/directory;application/x-7z-compressed;application/zip;application/gzip;
  '';

  xdg.desktopEntries.nvim = {
    name = "Neovim (NixVim)";
    genericName = "Editor";
    comment = "Edit text files";
    exec = "wezterm start -- nvim %F";
    terminal = false;
    icon = "nvim";
    type = "Application";
    mimeType = [
      "text/plain"
      "text/x-java"
      "text/x-csrc"
      "text/x-c++src"
      "text/x-python"
      "application/json"
      "text/html"
      "text/css"
      "application/javascript"
    ];
    categories = [ "Development" "Utility" "TextEditor" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "okularApplication_pdf.desktop" ];
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "text/plain" = [ "nvim.desktop" ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
  };
}
