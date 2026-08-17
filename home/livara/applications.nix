{ config, pkgs, lib, inputs, self, ... }:
let
  xournalppLocalConfig = "${config.home.homeDirectory}/.config/xournalpp";
  xournalppLegacyConfig = "${config.home.homeDirectory}/.config/nixos/xournalpp";
  xournalppSettings = pkgs.writeText "xournalpp-settings.xml" (builtins.replaceStrings
    [ "/home/livara/.config/xournalpp" "tokyo-night.gpl" ]
    [ "${config.home.homeDirectory}/.config/xournalpp" "serpantinum.gpl" ]
    (builtins.readFile "${inputs.xournal-conf}/xournalpp/settings.xml"));
  xournalppToolbar = pkgs.writeText "xournalpp-toolbar.ini" (builtins.replaceStrings
    [ "toolbarTop1=PEN,ERASER,HIGHLIGHTER" ]
    [ "toolbarTop1=HIGHLIGHTER,ERASER,PEN" ]
    (builtins.readFile "${inputs.xournal-conf}/xournalpp/toolbar.ini"));
in
{
  # Applications
  programs.nixvim = {
    enable = true;
    imports = [ inputs.vim-conf.lib.nixvimModule ];
    extraConfigLua = ''
      local ok, theme = pcall(dofile, vim.fn.expand("~/.config/nvim/matugen_colors.lua"))
      if ok and type(theme) == "table" then
        vim.g.colors_name = "serpantinum-matugen"
        vim.opt.background = "dark"
        vim.api.nvim_set_hl(0, "Normal", { fg = theme.text, bg = theme.base })
        vim.api.nvim_set_hl(0, "NormalFloat", { fg = theme.text, bg = theme.surface0 })
        vim.api.nvim_set_hl(0, "SignColumn", { bg = theme.base })
        vim.api.nvim_set_hl(0, "LineNr", { fg = theme.overlay1, bg = theme.base })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = theme.blue, bg = theme.base, bold = true })
        vim.api.nvim_set_hl(0, "String", { fg = theme.green })
        vim.api.nvim_set_hl(0, "Function", { fg = theme.blue })
        vim.api.nvim_set_hl(0, "Keyword", { fg = theme.mauve })
        vim.api.nvim_set_hl(0, "Type", { fg = theme.yellow })
        vim.api.nvim_set_hl(0, "Error", { fg = theme.red })
      end
    '';
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
      $DRY_RUN_CMD sed -i 's/tokyo-night\.gpl/serpantinum.gpl/g' "${xournalppLocalConfig}/settings.xml"
    elif [ ! -e "${xournalppLocalConfig}/settings.xml" ]; then
      $DRY_RUN_CMD cp "${xournalppSettings}" "${xournalppLocalConfig}/settings.xml"
    fi
    if [ ! -e "${xournalppLocalConfig}/toolbar.ini" ]; then
      $DRY_RUN_CMD cp "${xournalppToolbar}" "${xournalppLocalConfig}/toolbar.ini"
    fi
  '';
  xdg.configFile."xournalpp/default_template.tex".source = "${inputs.xournal-conf}/xournalpp/default_template.tex";

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
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
  };
}
