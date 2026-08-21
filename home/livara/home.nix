{ config, inputs, lib, pkgs, desktopProfile ? { }, userName ? "livara", ... }:
let
  isMyMachine = (desktopProfile.monitorProfile or "myMachine") == "myMachine";
  barRightWidgets = if isMyMachine then [
    { id = "livaraProductivity"; enabled = true; }
    {
      id = "diskUsage";
      enabled = true;
      mountPath = "/";
      diskUsageMode = 0;
      showMountPath = true;
      minimumWidth = true;
    }
    "cpuUsage"
    "memUsage"
    "controlCenterButton"
  ] else [
    # The Latitude has no tablet integration in its bar. Keep the productivity
    # plugin available to the launcher, but do not place its tablet widget
    # before the clock/calendar area.
    "systemTray"
    {
      id = "diskUsage";
      enabled = true;
      mountPath = "/";
      diskUsageMode = 0;
      showMountPath = true;
      minimumWidth = true;
    }
    "cpuUsage"
    "memUsage"
    "battery"
    "controlCenterButton"
  ];
  controlCenterWidgets = [
    { id = "volumeSlider"; enabled = true; width = 50; }
    { id = "brightnessSlider"; enabled = true; width = 50; }
    { id = "audioOutput"; enabled = true; width = 50; }
    { id = "audioInput"; enabled = true; width = 50; }
    { id = "nightMode"; enabled = true; width = 50; }
  ] ++ lib.optional (!isMyMachine) { id = "bluetooth"; enabled = true; width = 50; };
in
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

  # DMS v1.5.3 stores launcher options and GTK/Qt theming flags in
  # SettingsData at ~/.config/DankMaterialShell/settings.json. SessionData
  # (session.json) is reserved for wallpaper, locale, weather and runtime state.
  # Keep the settings contract declarative and write it atomically after HM has
  # materialized the DMS settings file, so stale runtime values cannot shadow it.
  home.activation.livaraDmsSettingsDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${config.xdg.configHome}/DankMaterialShell/settings.json"
    if [ -f "$settings" ]; then
      tmp="$settings.tmp.$$"
      ${pkgs.jq}/bin/jq \
        --arg logo "$HOME/.local/share/livara/icons/livara-launcher-logo.svg" \
        '.launcherLogoMode = "custom"
         | .launcherLogoCustomPath = $logo
         | .launcherLogoColorOverride = ""
         | .launcherLogoColorInvertOnMode = false
         | .launcherLogoBrightness = 0.5
         | .launcherLogoContrast = 1
         | .launcherLogoSizeOffset = -2
         | .gtkThemingEnabled = true
         | .qtThemingEnabled = true
         | .runDmsMatugenTemplates = true
         | .matugenTemplateGtk = true
         | .matugenTemplateNiri = true
         | .matugenTemplateQt5ct = true
         | .matugenTemplateQt6ct = true
         | .matugenTemplateKcolorscheme = true
         | .matugenTemplateFirefox = true
         | .matugenTemplateZenBrowser = true
         | .matugenTemplateVesktop = true
         | .matugenTemplateWezterm = true
         | .matugenTemplateNeovim = false
         | .matugenTemplateNeovimSetBackground = false' \
        "$settings" > "$tmp"
      chmod 0644 "$tmp"
      mv -f "$tmp" "$settings"
    fi
  '';

  # PluginService stores plugin settings in its own JSON file. The vendored
  # carousel uses the manifest ID `wallpaper-carousel`, not the Nix attribute
  # name, so enforce both expansion flags at the runtime contract boundary.
  home.activation.livaraWallpaperCarouselDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    plugin_settings="${config.xdg.configHome}/DankMaterialShell/plugin_settings.json"
    mkdir -p "$(dirname "$plugin_settings")"
    tmp="$plugin_settings.tmp.$$"
    if [ -f "$plugin_settings" ]; then
      ${pkgs.jq}/bin/jq \
        '."wallpaper-carousel".expandSelected = "false"
         | ."wallpaper-carousel".enableHoldExpand = "false"' \
        "$plugin_settings" > "$tmp"
    else
      ${pkgs.jq}/bin/jq -n \
        '{"wallpaper-carousel": {"expandSelected": "false", "enableHoldExpand": "false"}}' \
        > "$tmp"
    fi
    chmod 0644 "$tmp"
    mv -f "$tmp" "$plugin_settings"
  '';

  # EasyEffects is a GUI effect processor, not the audio device manager.
  # Keep it available as an application but do not start its hidden service at
  # every login; DMS/PipeWire own device selection and AudioRelay owns the
  # Virtual-Mic source contract.
  services.easyeffects.enable = false;

  # DMS checks the conventional `.face` path before `.face.icon` for both
  # greeter users and the profile card. Keep both links declarative so an old
  # manually-created file cannot shadow the selected avatar.
  home.file.".face" = {
    source = builtins.path {
      path = ../../Icons/6afde16e1ef1cb3257b30e01890787dd.jpg;
      name = "livara-profile-icon";
    };
    force = true;
  };
  home.file.".face.icon" = {
    source = builtins.path {
      path = ../../Icons/6afde16e1ef1cb3257b30e01890787dd.jpg;
      name = "livara-profile-icon";
    };
    force = true;
  };
  home.file."Fire/.keep".text = "";

  programs.livara.visual = {
    enable = true;
    launcherLogoAsset = ../../icons/livara-launcher-logo.svg;
    wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
    themeName = "Livara";
    dmsPackage = inputs.dms.packages.${pkgs.system}.default;
    # The login service selects one image from ~/Wallpapers through DMS IPC;
    # DMS remains the sole wallpaper/Matugen owner.
    wallpaperAutomationEnabled = true;
    weatherEnabled = true;
    weatherAddress = "Jardim João XXIII, São Paulo, SP, Brasil";
    systemMonitorEnabled = true;

    # DMS v1.5.3 owns the shell theme and runs Matugen. The application
    # adapters from shell-conf remain enabled through its user-template hook.
    dmsSettings = {
      currentThemeName = "dynamic";
      currentThemeCategory = "generic";
      matugenScheme = "scheme-tonal-spot";
      matugenContrast = 0;
      runUserMatugenTemplates = true;
      runDmsMatugenTemplates = true;
      matugenTemplateGtk = true;
      matugenTemplateNiri = true;
      matugenTemplateQt5ct = true;
      matugenTemplateQt6ct = true;
      matugenTemplateFirefox = true;
      matugenTemplateZenBrowser = true;
      matugenTemplateVesktop = true;
      matugenTemplateKitty = true;
      matugenTemplateWezterm = true;
      # NixVim owns its transparent theme and consumes the shared
      # matugen_colors.lua generated by shell-conf. DMS's base46 Neovim
      # template would replace lualine's Livara groups and reintroduce an
      # opaque/statusline-specific background.
      matugenTemplateNeovim = false;
      matugenTemplateNeovimSetBackground = false;
      gtkThemingEnabled = true;
      qtThemingEnabled = true;
      terminalsAlwaysDark = true;
      # DMS surface alpha is separate from niri window opacity. Keep the
      # shell surfaces consistent with the compositor policy.
      popupTransparency = 0.90;
      dockTransparency = 0.90;
      blurEnabled = true;
      blurForegroundLayers = true;
      notificationForegroundLayers = true;
      useAutoLocation = false;
      weatherEnabled = true;
      firstDayOfWeek = 1;
      calendarBackend = "dankcal";
      iconThemeDark = "Kora";
      iconThemeLight = "Kora";
      iconThemePerMode = false;
      launcherLogoMode = "custom";
      launcherLogoCustomPath = "${config.home.homeDirectory}/.local/share/livara/icons/livara-launcher-logo.svg";
      # Empty override delegates the SVG color to DMS's current primary theme
      # color; -2 is the requested small reduction from the upstream size.
      launcherLogoColorOverride = "";
      launcherLogoSizeOffset = -2;
      launcherLogoBrightness = 0.5;
      launcherLogoContrast = 1.0;
      launcherLogoColorInvertOnMode = false;
      cursorSettings = {
        theme = "Bibata-Modern-Classic";
        size = 24;
        niri = { hideWhenTyping = false; hideAfterInactiveMs = 0; };
      };
      showWeather = true;
      showMusic = true;
      showCpuUsage = true;
      showMemUsage = true;
      showCpuTemp = true;
      showGpuTemp = false;
      showBattery = !isMyMachine;
      showBatteryPercent = !isMyMachine;
      # Niri supplies the occupied workspace model. Do not render numeric
      # labels in the bar; users navigate with native niri workspace actions.
      showOccupiedWorkspacesOnly = true;
      showWorkspaceIndex = false;
      showWorkspaceName = false;
      showWorkspaceApps = true;
      controlCenterShowNetworkIcon = true;
      controlCenterShowBluetoothIcon = !isMyMachine;
      controlCenterShowBatteryIcon = !isMyMachine;
      controlCenterShowAudioIcon = true;
      controlCenterWidgets = controlCenterWidgets;
      dashTabs = [
        { id = "overview"; enabled = true; }
        { id = "media"; enabled = true; }
        { id = "wallpaper"; enabled = true; }
        { id = "weather"; enabled = true; }
      ];
      barConfigs = [
        {
          id = "default";
          enabled = true;
          name = "Livara Bar";
          screenPreferences = [ "all" ];
          showOnLastDisplay = true;
          leftWidgets = [
            "launcherButton"
            "workspaceSwitcher"
            {
              id = "focusedWindow";
              enabled = true;
              focusedWindowCompactMode = true;
              focusedWindowSize = 0;
            }
          ];
          centerWidgets = [ "music" "clock" "weather" ];
          rightWidgets = barRightWidgets;
          spacing = 4;
          barInsetPadding = 8;
          bottomGap = 1;
          transparency = 0.75;
          widgetTransparency = 0.75;
          squareCorners = false;
          noBackground = true;
          maximizeWidgetIcons = false;
          maximizeWidgetText = false;
          removeWidgetPadding = false;
          widgetPadding = 10;
          gothCornersEnabled = false;
          gothCornerRadiusOverride = false;
          gothCornerRadiusValue = 12;
          borderEnabled = false;
          borderColor = "surfaceText";
          borderOpacity = 1.0;
          borderThickness = 1;
          widgetOutlineEnabled = false;
          widgetOutlineColor = "primary";
          widgetOutlineOpacity = 1.0;
          widgetOutlineThickness = 1;
          fontScale = 1.01;
          iconScale = 1.06;
          autoHide = false;
          autoHideStrict = false;
          autoHideDelay = 250;
          showOnWindowsOpen = false;
          openOnOverview = false;
          visible = true;
          popupGapsAuto = true;
          popupGapsManual = 4;
          maximizeDetection = true;
          useOverlayLayer = false;
          scrollEnabled = true;
          scrollXBehavior = "column";
          scrollYBehavior = "workspace";
          shadowIntensity = 0;
          shadowOpacity = 60;
          shadowColorMode = "default";
          shadowCustomColor = "#000000";
          clickThrough = false;
          hoverPopouts = true;
          hoverPopoutDelay = 415;
        }
      ];
    };

    dmsSession = {
      wallpaperPath = "${config.home.homeDirectory}/Wallpapers/purple5.png";
      perMonitorWallpaper = false;
      perModeWallpaper = false;
      wallpaperCyclingEnabled = false;
      wallpaperTransition = "random";
      isLightMode = false;
      nightModeEnabled = false;
      nightModeUseIPLocation = false;
      latitude = -23.599722;
      longitude = -46.791389;
      weatherLocation = "Jardim João XXIII, São Paulo, SP, Brasil";
      weatherCoordinates = "-23.599722,-46.791389";
      weatherHourlyDetailed = true;
      locale = "pt_BR";
      timeLocale = "pt_BR";
      # SessionData owns the launcher hidden-app list (not settings.json).
      hiddenApps = [ ];
      searchAppActions = true;
    };

    dmsPlugins = {
      livaraProductivity = {
        src = inputs.shell-conf + "/src/livara/dms-plugins/livara";
      };
      wallpaperCarousel = {
        # Vendored in shell-conf so the HD-capped hold preview is reproducible
        # instead of relying on an unmodified upstream source tree.
        src = inputs.shell-conf + "/src/livara/dms-plugins/wallpaperCarousel";
        settings = {
          wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
          carouselMode = "wrap";
          overlayOpacity = 80;
          borderWidth = 3;
          cornerRadius = 12;
          itemWidth = 280;
          itemHeight = 420;
          selectedScale = 108;
          expandSelected = "false";
          expandMultiplier = 135;
          enableHoldExpand = "false";
          holdExpandRatio = 65;
          holdDelay = 900;
          cacheSize = 30;
        };
      };
      wallpaperWatcherDaemon = {
        src = inputs.dms + "/quickshell/PLUGINS/WallpaperWatcherDaemon";
        settings.scriptPath = "${config.home.homeDirectory}/.local/bin/livara-matugen-sync";
      };
    };
  };

  # niri provides native systemd session integration. Bind DMS to niri.service
  # so logout/login starts the shell with the compositor session instead of
  # relying on a generic graphical-session.target activation.
  programs.dank-material-shell.systemd.target = "niri.service";

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projetos";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };
}
