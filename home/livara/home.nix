{ config, inputs, lib, pkgs, desktopProfile ? { }, userName ? "livara", ... }:
let
  isMyMachine = (desktopProfile.monitorProfile or "myMachine") == "myMachine";
  nixHost = if isMyMachine then "myMachine" else "latitude";
  barRightWidgets = [ "systemTray" "clipboard" "cpuUsage" "memUsage" "nixMonitor" "notificationButton" "controlCenterButton" ]
    ++ lib.optional (!isMyMachine) "battery";
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
  services.easyeffects.enable = true;

  # Nix Monitor owns its plugin files and config.json through its official
  # Home Manager module; the command remains explicit and host-aware.
  programs.nix-monitor = {
    enable = true;
    rebuildCommand = [
      "bash"
      "-lc"
      "cd ${config.home.homeDirectory}/Projetos/nix-conf && sudo nixos-rebuild switch --flake .#${nixHost} 2>&1"
    ];
    gcCommand = [ "bash" "-lc" "sudo nix-collect-garbage -d 2>&1" ];
    updateInterval = 300;
    nixpkgsChannel = "nixos-unstable";
  };

  home.file.".face.icon".source = builtins.path {
    path = ../../Icons/6afde16e1ef1cb3257b30e01890787dd.jpg;
    name = "livara-profile-icon";
  };
  home.file.".local/share/livara/icons/livara.jpg".source = builtins.path {
    path = ../../Icons/6afde16e1ef1cb3257b30e01890787dd.jpg;
    name = "livara-shell-icon";
  };
  home.file."Fire/.keep".text = "";

  programs.livara.visual = {
    enable = true;
    wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
    themeName = "Livara";
    dmsPackage = inputs.dms.packages.${pkgs.system}.default;
    wallpaperAutomationEnabled = false;
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
      matugenTemplateQt5ct = true;
      matugenTemplateQt6ct = true;
      matugenTemplateFirefox = true;
      matugenTemplateZenBrowser = true;
      matugenTemplateVesktop = true;
      matugenTemplateKitty = true;
      matugenTemplateWezterm = true;
      matugenTemplateNeovim = true;
      matugenTemplateNeovimSetBackground = true;
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
      calendarBackend = "khal";
      iconThemeDark = "Kora";
      iconThemeLight = "Kora";
      iconThemePerMode = false;
      launcherLogoMode = "custom";
      launcherLogoCustomPath = "${config.home.homeDirectory}/.local/share/livara/icons/livara.jpg";
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
      showOccupiedWorkspacesOnly = true;
      showWorkspaceIndex = true;
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
          leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
          centerWidgets = [ "music" "clock" "weather" ];
          rightWidgets = barRightWidgets;
          spacing = 4;
          innerPadding = 4;
          bottomGap = 0;
          transparency = 0.90;
          widgetTransparency = 0.90;
          squareCorners = false;
          noBackground = false;
          maximizeWidgetIcons = false;
          maximizeWidgetText = false;
          removeWidgetPadding = false;
          widgetPadding = 8;
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
          fontScale = 1.0;
          iconScale = 1.0;
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
          hoverPopouts = false;
          hoverPopoutDelay = 150;
        }
      ];
    };

    dmsSession = {
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
      hiddenApps = [ "ikhal" ];
      searchAppActions = true;
    };

    dmsPlugins = {
      livaraProductivity = {
        src = inputs.shell-conf + "/src/livara/dms-plugins/livara";
      };
      wallpaperCarousel = {
        src = inputs.wallpaperCarousel;
        settings = {
          wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
          carouselMode = "wrap";
          overlayOpacity = 80;
          borderWidth = 3;
          cornerRadius = 12;
          itemWidth = 280;
          itemHeight = 420;
          selectedScale = 108;
          expandSelected = "true";
          expandMultiplier = 135;
          enableHoldExpand = "true";
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

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projetos";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };
}
