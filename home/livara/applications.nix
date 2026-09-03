{
  config,
  pkgs,
  lib,
  inputs,
  self,
  ...
}:
let
  studyPlanner = inputs.study-planner.packages.${pkgs.stdenv.hostPlatform.system}.default;
  materialFoxSource = pkgs.fetchFromGitHub {
    owner = "edelvarden";
    repo = "material-fox-updated";
    rev = "523cac082012baaaabc4ddbb62f63769c0cb4e32";
    hash = "sha256-ZzigMIPHyfNxfJc2bYpvztz1FUbTOdEH+AZv+bivH/M=";
  };
  materialFox = pkgs.stdenvNoCC.mkDerivation {
    pname = "material-fox-updated";
    version = "2026-09-02";
    src = materialFoxSource;
    nativeBuildInputs = [ pkgs.dart-sass ];
    dontConfigure = true;
    installPhase = ''
      mkdir -p "$out/chrome"
      sass --quiet --no-source-map --style compressed src/user-chrome.scss "$out/chrome/user-chrome.css"
      sass --quiet --no-source-map --style compressed src/user-content.scss "$out/chrome/user-content.css"
      cp chrome/theme-material-blue.css "$out/chrome/"
      cp -r chrome/fonts chrome/icons "$out/chrome/"
    '';
  };
  noctaliaFirefoxCss = "${config.xdg.stateHome}/livara/theme/browser/firefox.css";
  materialFoxUserChrome = pkgs.writeText "livara-firefox-userChrome.css" ''
    @import url("file://${materialFox}/chrome/user-chrome.css");
    @import url("file://${materialFox}/chrome/theme-material-blue.css");
    @import url("file://${noctaliaFirefoxCss}");
  '';
  materialFoxUserContent = pkgs.writeText "livara-firefox-userContent.css" ''
    @import url("file://${materialFox}/chrome/user-content.css");
    @import url("file://${materialFox}/chrome/theme-material-blue.css");
    @import url("file://${noctaliaFirefoxCss}");
  '';

  # One Zen profile owns four Spaces, each with its own container and Essentials.

  # Shared preferences and the Noctalia-generated userChrome import.
  zenProfileSettings = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "zen.workspaces.continue-where-left-off" = true;
    "zen.view.compact.enable-at-startup" = true;
    "zen.view.compact.hide-tabbar" = true;
    "zen.view.compact.hide-toolbar" = false;
    "zen.urlbar.behavior" = "float";
    "zen.workspaces.container-specific-essentials-enabled" = true;
    "zen.window-sync.enabled" = true;
    "zen.window-sync.sync-only-pinned-tabs" = true;
  };

  zenProfileSearch = {
    force = true;
    default = "ddg";
  };

  zenProfileUserChrome = ''
    @import url("${config.xdg.stateHome}/livara/theme/browser/zen.css");
  '';

  # One profile-local container per Space keeps each Essentials strip isolated.
  zenContainers = {
    Personal = {
      id = 1;
      color = "purple";
      icon = "fingerprint";
    };
    School = {
      id = 2;
      color = "blue";
      icon = "briefcase";
    };
    Programming = {
      id = 3;
      color = "turquoise";
      icon = "circle";
    };
    Hobby = {
      id = 4;
      color = "green";
      icon = "chill";
    };
  };

  # Seed only a valid empty session store; the upstream writer performs the merge.
  zenSessionBootstrap = pkgs.writeShellApplication {
    name = "bootstrap-zen-session-stores";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      lsof
      mozlz4a
      procps
    ];
    text = ''
      set -Eeuo pipefail

      profile=personal
        profile_dir="${config.xdg.configHome}/zen/$profile"
        sessions_file="$profile_dir/zen-sessions.jsonlz4"
        lock_file="$profile_dir/.parentlock"
        valid_store=0

        # Ignore empty or malformed stores after interrupted shutdowns/resets.
        if [[ -s "$sessions_file" ]]; then
          json_tmp="$(mktemp)"
          if mozlz4a -d "$sessions_file" "$json_tmp" >/dev/null 2>&1 \
            && jq -e '(.spaces | type == "array") and (.tabs | type == "array")' "$json_tmp" >/dev/null 2>&1; then
            valid_store=1
          fi
          rm -f "$json_tmp"
        fi
        if (( valid_store == 1 )); then
          exit 0
        fi

        # Never seed a live profile; close Zen and rerun the switch instead.
        if lsof "$lock_file" >/dev/null 2>&1 \
          || pgrep -x zen >/dev/null 2>&1 \
          || pgrep -x zen-beta >/dev/null 2>&1 \
          || pgrep -x zen-twilight >/dev/null 2>&1 \
          || pgrep -x "zen-$profile" >/dev/null 2>&1; then
          echo "zen-sessions: Zen appears to be running; bootstrap skipped for '$profile'"
          exit 0
        fi

        install -d "$profile_dir"
        json_tmp="$(mktemp)"
        staging_dir="$(mktemp -d "$profile_dir/.zen-sessions-staging.XXXXXX")"
        compressed_tmp="$staging_dir/zen-sessions.jsonlz4"
        printf '%s\n' '{"spaces":[],"tabs":[],"folders":[],"groups":[],"splitViewData":[]}' > "$json_tmp"
        mozlz4a "$json_tmp" "$compressed_tmp"
        install -m 0600 "$compressed_tmp" "$sessions_file"
        rm -rf "$staging_dir" "$json_tmp"
        echo "zen-sessions: seeded empty store for '$profile'"
    '';
  };

  # Recovery is explicit and backup-first; normal activation never resets user state.
  zenSessionReset = pkgs.writeShellApplication {
    name = "reset-zen-session-store";
    runtimeInputs = with pkgs; [
      coreutils
      lsof
      mozlz4a
      procps
    ];
    text = ''
      set -Eeuo pipefail

      if [[ "''${1:-}" != "--confirm" ]]; then
        echo "Refusing to reset Zen session state without --confirm."
        echo "This keeps a timestamped backup, but removes current Spaces/pins from the active store."
        exit 2
      fi

      profile=personal
      profile_dir="${config.xdg.configHome}/zen/$profile"
      sessions_file="$profile_dir/zen-sessions.jsonlz4"
      lock_file="$profile_dir/.parentlock"

      if lsof "$lock_file" >/dev/null 2>&1 \
        || pgrep -x zen >/dev/null 2>&1 \
        || pgrep -x zen-beta >/dev/null 2>&1 \
        || pgrep -x zen-twilight >/dev/null 2>&1; then
        echo "Refusing to reset while Zen Browser is running."
        exit 1
      fi

      install -d "$profile_dir"
      backup_file="$sessions_file.backup-$(date -u +%Y%m%dT%H%M%SZ)"
      if [[ -e "$sessions_file" ]]; then
        cp -a "$sessions_file" "$backup_file"
      fi

      json_tmp="$(mktemp)"
      staging_dir="$(mktemp -d "$profile_dir/.zen-sessions-reset.XXXXXX")"
      trap 'rm -f "$json_tmp"; rm -rf "$staging_dir"' EXIT
      compressed_tmp="$staging_dir/zen-sessions.jsonlz4"
      printf '%s\n' '{"spaces":[],"tabs":[],"folders":[],"groups":[],"splitViewData":[]}' > "$json_tmp"
      mozlz4a "$json_tmp" "$compressed_tmp"
      install -m 0600 "$compressed_tmp" "$sessions_file"

      echo "Zen session store reset to a valid empty state."
      [[ -e "$backup_file" ]] && echo "Backup: $backup_file"
      echo "Close Zen, run the myMachine rebuild, then run verify-zen-session-stores."
    '';
  };

  # Post-activation evidence is non-destructive and never fails the switch.
  zenSessionVerify = pkgs.writeShellApplication {
    name = "verify-zen-session-stores";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      mozlz4a
    ];
    text = ''
            set -u
            status_file="${config.xdg.stateHome}/livara/zen-session-status.txt"
            install -D -m 0644 /dev/null "$status_file"
            : > "$status_file"

            profile="personal"
            sessions_file="${config.xdg.configHome}/zen/$profile/zen-sessions.jsonlz4"
            json_tmp="$(mktemp)"
            if [[ ! -s "$sessions_file" ]] \
              || ! mozlz4a -d "$sessions_file" "$json_tmp" >/dev/null 2>&1 \
              || ! jq -e '(.spaces | type == "array") and (.tabs | type == "array")' "$json_tmp" >/dev/null 2>&1; then
              printf '%s\tMISSING_OR_INVALID\n' "$profile" | tee -a "$status_file"
              rm -f "$json_tmp"
              exit 0
            fi

            total_spaces="$(jq '(.spaces // []) | length' "$json_tmp")"
            total_essentials="$(jq '[.tabs[]? | select(.zenEssential == true)] | length' "$json_tmp")"
            printf '%s\tspaces=%s\tessentials=%s\n' "$profile" "$total_spaces" "$total_essentials" | tee -a "$status_file"

            while IFS='|' read -r space space_id container_id; do
              [[ -n "$space" ]] || continue
              workspace="{$space_id}"
              spaces="$(jq --arg workspace "$workspace" '[.spaces[]? | select(.uuid == $workspace)] | length' "$json_tmp")"
              essentials="$(jq --arg workspace "$workspace" --argjson container "$container_id" '[.tabs[]? | select(.zenWorkspace == $workspace and .zenEssential == true and .userContextId == $container)] | length' "$json_tmp")"
              printf '%s\tspace=%s\tspaces=%s\tessentials=%s\tcontainer=%s\n' "$profile" "$space" "$spaces" "$essentials" "$container_id" | tee -a "$status_file"
              if [[ "$spaces" -ne 1 || "$essentials" -ne 4 ]]; then
                printf '%s\tWARNING expected exactly 1 Space and 4 container-scoped Essentials\n' "$space" | tee -a "$status_file"
              fi
            done <<'EOF'
      Personal|f1e6811d-d3a4-4d65-aa05-6ea5b23e75f3|1
      School|4fb4f402-d1f2-44e5-a9ea-c982a2e0a9a8|2
      Programming|5abe9e1a-ad06-43e7-b7ce-da15cdc90062|3
      Hobby|87178d47-21ed-4540-9739-9272e6a4ab3c|4
      EOF
            rm -f "$json_tmp"
    '';
  };

  xournalppLocalConfig = "${config.home.homeDirectory}/.config/xournalpp";
  xournalppLegacyConfig = "${config.home.homeDirectory}/.config/nixos/xournalpp";
  xournalppSettings = pkgs.writeText "xournalpp-settings.xml" (
    builtins.replaceStrings
      [ "/home/livara/.config/xournalpp" "tokyo-night.gpl" ]
      [ "${config.home.homeDirectory}/.config/xournalpp" "livara.gpl" ]
      (builtins.readFile "${inputs.xournal-conf}/xournalpp/settings.xml")
  );
  xournalppToolbar = pkgs.writeText "xournalpp-toolbar.ini" (
    builtins.replaceStrings
      [ "toolbarTop1=PEN,ERASER,HIGHLIGHTER" ]
      [ "toolbarTop1=HIGHLIGHTER,ERASER,PEN" ]
      (builtins.readFile "${inputs.xournal-conf}/xournalpp/toolbar.ini")
  );
  xournalppPalette = "${inputs.xournal-conf}/xournalpp/palettes/livara.gpl";

  spicetifyAdblockSource = pkgs.fetchFromGitHub {
    owner = "rxri";
    repo = "spicetify-extensions";
    rev = "64cb2b8c235b13cf943e4c265c19199f69e5d170";
    hash = "sha256-gzmKE1wMPIBrtJ2NhkaFlx8Q8wCGjDjALhH8TewVMyQ=";
  };
  spicetifyThemeSource = pkgs.writeTextDir "user.css" ''
    :root {
      --spice-text: #eef2f7;
      --spice-subtext: #b2bdca;
      --spice-main: #111318;
      --spice-sidebar: #0b0d12;
      --spice-player: #111318;
      --spice-card: #1a2029;
      --spice-shadow: #07090d;
      --spice-button: #7bb7ff;
      --spice-button-active: #9bc9ff;
      --spice-button-disabled: #596575;
      --spice-tab-active: #263b55;
      --spice-notification: #254634;
      --spice-notification-error: #512d34;
      --spice-misc: #c2a4f5;
    }

    .Root__main-view,
    .main-rootlist-rootlist,
    .Root__now-playing-bar {
      background: var(--spice-main) !important;
    }

    .main-card-card,
    .main-trackList-trackListRow:hover,
    .main-rootlist-rootlistItem:hover {
      background: var(--spice-card) !important;
    }

    .main-leaderboardComponent-container,
    [data-testid="ad-slot"],
    [data-testid="topbar-ad-container"] {
      display: none !important;
    }

    .x-progressBar-fillColor,
    .main-playButton-button {
      background-color: var(--spice-button) !important;
    }
  '';
  spicetifyColorScheme = {
    text = "EEF2F7";
    subtext = "B2BDCA";
    main = "111318";
    sidebar = "0B0D12";
    player = "111318";
    card = "1A2029";
    shadow = "07090D";
    selected-row = "263B55";
    button = "7BB7FF";
    button-active = "9BC9FF";
    button-disabled = "596575";
    tab-active = "263B55";
    notification = "254634";
    notification-error = "512D34";
    misc = "C2A4F5";
  };
  matugenConfig = pkgs.writeText "livara-matugen-config.toml" ''
    [config]
    fallback_color = "#7bb7ff"
    caching = false

    [templates.intellij-dark]
    input_path = "${./intellij-matugen.icls}"
    output_path = "${config.xdg.stateHome}/livara/theme/intellij/Matugen-Dark.icls"
  '';

in
{
  # Applications
  programs.spicetify = {
    enable = true;
    theme = {
      name = "Livara";
      src = spicetifyThemeSource;
      injectCss = true;
      injectThemeJs = false;
      replaceColors = true;
      homeConfig = true;
      overwriteAssets = false;
    };
    colorScheme = "custom";
    customColorScheme = spicetifyColorScheme;
    enabledExtensions = [
      {
        src = spicetifyAdblockSource + /adblock;
        name = "adblock.js";
      }
    ];
  };

  programs.nixvim = {
    enable = true;
    imports = [ inputs.vim-conf.lib.nixvimModule ];
  };

  xdg.configFile."matugen/config.toml".source = matugenConfig;

  programs.zen-browser = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;

      # Force-install extensions; keep only Bitwarden on the toolbar.
      ExtensionSettings =
        let
          mkExt = installUrl: {
            inherit installUrl;
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
          mkPinned = installUrl: {
            inherit installUrl;
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          amo = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
        in
        {
          # uBlock Origin
          "uBlock0@raymondhill.net" = mkExt (amo "ublock-origin");
          # Bitwarden — pinned to the toolbar
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkPinned (amo "bitwarden-password-manager");
          # SponsorBlock
          "sponsorBlocker@ajay.app" = mkExt (amo "sponsorblock");
          # Privacy Badger
          "jid1-MnnxcxisBPnSXQ@jetpack" = mkExt (amo "privacy-badger17");
          # Return YouTube Dislike
          "returnytdislike@shand.ch" = mkExt (amo "return-youtube-dislike-firefox");
          # Search by Image
          "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}" = mkExt (amo "search_by_image");
          # Dark Reader applies dark styles to website content.
          "{9ed7d361-ccd9-4cad-9846-977da2651fb5}" = {
            installation_mode = "blocked";
          };
          "addon@darkreader.org" = mkExt (amo "darkreader");
        };
    };

    # One profile contains four Spaces; each maps to one container and four Essentials.
    # Close Zen before switching so the writer can merge session state safely.
    profiles = {
      "personal" = {
        id = 0;
        name = "Personal";
        path = "personal";
        storeId = "f1e6811d";
        isDefault = true;
        spacesForce = true;
        containers = {
          Personal = zenContainers.Personal;
          School = zenContainers.School;
          Programming = zenContainers.Programming;
          Hobby = zenContainers.Hobby;
        };
        containersForce = true;
        spaces = {
          "Personal" = {
            id = "f1e6811d-d3a4-4d65-aa05-6ea5b23e75f3";
            position = 1000;
            icon = "chrome://browser/skin/zen-icons/home.svg";
            container = 1;
            pins = {
              "YouTube" = {
                id = "fb42feb2-aeb4-4c68-b0e6-ec45ad97aef5";
                url = "https://www.youtube.com";
                position = 100;
                isEssential = true;
                container = 1;
              };
              "WhatsApp" = {
                id = "234e1296-1b77-484c-a409-bf50d441adc6";
                url = "https://web.whatsapp.com";
                position = 200;
                isEssential = true;
                container = 1;
              };
              "Discord" = {
                id = "49af7c02-464e-44d4-8a01-f77d90325fb0";
                url = "https://discord.com/app";
                position = 300;
                isEssential = true;
                container = 1;
              };
              "Reddit" = {
                id = "aa126b37-fd04-49a0-be36-ee84fe5454e6";
                url = "https://www.reddit.com";
                position = 400;
                isEssential = true;
                container = 1;
              };
            };
          };
          "School" = {
            id = "4fb4f402-d1f2-44e5-a9ea-c982a2e0a9a8";
            position = 2000;
            icon = "chrome://browser/skin/zen-icons/selectable/briefcase.svg";
            container = 2;
            pins = {
              "Desmos" = {
                id = "022f0024-d7f5-4560-a930-576398b7fe11";
                url = "https://www.desmos.com/calculator";
                position = 100;
                isEssential = true;
                container = 2;
              };
              "Telegram" = {
                id = "8a6ecd1f-22d0-4293-bed9-d5775d4e7cae";
                url = "https://web.telegram.org";
                position = 200;
                isEssential = true;
                container = 2;
              };
              "Wolfram Alpha" = {
                id = "6e06385b-7876-4861-9b02-cb2cdb5e5010";
                url = "https://www.wolframalpha.com";
                position = 300;
                isEssential = true;
                container = 2;
              };
              "Project Euler" = {
                id = "650a2fca-7fef-4f31-86f1-3c6d250c0057";
                url = "https://projecteuler.net/archives";
                position = 400;
                isEssential = true;
                container = 2;
              };
            };
          };
          "Programming" = {
            id = "5abe9e1a-ad06-43e7-b7ce-da15cdc90062";
            position = 3000;
            icon = "chrome://browser/skin/zen-icons/selectable/code.svg";
            container = 3;
            pins = {
              "Alura" = {
                id = "50f9e374-7439-49d3-ae22-5b5ffb24a0bb";
                url = "https://www.alura.com.br/";
                position = 100;
                isEssential = true;
                container = 3;
              };
              "OneCompiler" = {
                id = "b9b80d2d-dba1-41c9-9b76-2f55999670b4";
                url = "https://onecompiler.com";
                position = 200;
                isEssential = true;
                container = 3;
              };
              "DevDocs" = {
                id = "e2c333ea-c821-48ea-aa3e-4ae5def4029f";
                url = "https://devdocs.io";
                position = 300;
                isEssential = true;
                container = 3;
              };
              "GitHub" = {
                id = "e50b518d-73ce-4444-a2ce-90211905ae6a";
                url = "https://github.com";
                position = 400;
                isEssential = true;
                container = 3;
              };
            };
          };
          "Hobby" = {
            id = "87178d47-21ed-4540-9739-9272e6a4ab3c";
            position = 4000;
            icon = "chrome://browser/skin/zen-icons/selectable/game-controller.svg";
            container = 4;
            pins = {
              "Monkeytype" = {
                id = "08d3f6a7-ef95-494c-abe3-a5f16c5c8679";
                url = "https://monkeytype.com";
                position = 100;
                isEssential = true;
                container = 4;
              };
              "NixOS & Flakes" = {
                id = "356cd183-540b-4349-b4cd-a97a9ea52582";
                url = "https://nixos-and-flakes.ieda.me/";
                position = 200;
                isEssential = true;
                container = 4;
              };
              "GTNH Chinese Wiki" = {
                id = "d0d6a55e-7dc0-4c38-8d7b-cd1f3e8f7af9";
                url = "https://gtnh.huijiwiki.com/wiki/%E9%A6%96%E9%A1%B5";
                position = 300;
                isEssential = true;
                container = 4;
              };
              "NEPS Academy" = {
                id = "a2b50703-8af3-4479-9167-4711ce025679";
                url = "https://neps.academy/exercises";
                position = 400;
                isEssential = true;
                container = 4;
              };
            };
          };
        };
        pinsForce = true;
        pinsForceAction = "demote";
        search = zenProfileSearch;
        userChrome = zenProfileUserChrome;
        settings = zenProfileSettings;
      };
    };
  };

  # Replace only the generated userChrome file; other Zen state stays unmanaged.
  home.file."${config.xdg.configHome}/zen/personal/chrome/userChrome.css".force = true;

  # Seed the profile store after the write boundary and before the upstream writer.
  home.activation.bootstrapZenSessionStores =
    lib.hm.dag.entryBetween
      [
        "zen-browser-personal"
      ]
      [
        "writeBoundary"
      ]
      ''
        ${zenSessionBootstrap}/bin/bootstrap-zen-session-stores
      '';

  home.activation.verifyZenSessionStores =
    lib.hm.dag.entryAfter
      [
        "zen-browser-personal"
      ]
      ''
        $DRY_RUN_CMD "${zenSessionVerify}/bin/verify-zen-session-stores" || true
      '';
  home.file.".local/bin/reset-zen-session-store".source =
    "${zenSessionReset}/bin/reset-zen-session-store";
  home.file.".local/bin/verify-zen-session-stores".source =
    "${zenSessionVerify}/bin/verify-zen-session-stores";

  # Shared extension policy for Firefox and Zen; Firefox also gets Adaptive Tab Bar Colour.
  programs.firefox = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;

      # Force-install extensions; keep only Bitwarden on the toolbar.
      ExtensionSettings =
        let
          mkExt = installUrl: {
            inherit installUrl;
            installation_mode = "force_installed";
            default_area = "menupanel";
          };
          mkPinned = installUrl: {
            inherit installUrl;
            installation_mode = "force_installed";
            default_area = "navbar";
          };
          amo = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
        in
        {
          # uBlock Origin
          "uBlock0@raymondhill.net" = mkExt (amo "ublock-origin");
          # Bitwarden — pinned to the toolbar
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkPinned (amo "bitwarden-password-manager");
          # SponsorBlock
          "sponsorBlocker@ajay.app" = mkExt (amo "sponsorblock");
          # Privacy Badger
          "jid1-MnnxcxisBPnSXQ@jetpack" = mkExt (amo "privacy-badger17");
          # Return YouTube Dislike
          "returnytdislike@shand.ch" = mkExt (amo "return-youtube-dislike-firefox");
          # Search by Image
          "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}" = mkExt (amo "search_by_image");
          # Dark Reader applies dark styles to website content.
          "{9ed7d361-ccd9-4cad-9846-977da2651fb5}" = {
            installation_mode = "blocked";
          };
          "addon@darkreader.org" = mkExt (amo "darkreader");
          # Adaptive Tab Bar Colour — Firefox only
          "ATBC@EasonWong" = mkExt (amo "adaptive-tab-bar-colour");
        };
    };
    profiles.default = {
      id = 0;
      isDefault = true;
      search = {
        force = true;
        default = "ddg";
      };
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "layout.css.prefers-color-scheme.content-override" = 2;
        "svg.context-properties.content.enabled" = true;
        "userChrome.theme-material" = true;

        # Remove shortcuts from the new-tab page.
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.showSearchShortcuts" = false;
        "browser.newtabpage.activity-stream.default.sites" = "";
        "browser.topsites.contile.enabled" = false;
        "browser.newtabpage.activity-stream.system.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
      };
    };
  };

  # Firefox profiles are created by Firefox, so link managed chrome files after
  # profile creation instead of placing a second theme in the Nix store.
  home.activation.livaraFirefoxNoctaliaLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ff_dir="${config.home.homeDirectory}/.mozilla/firefox"
    if [ -d "$ff_dir" ]; then
      while IFS= read -r -d "" profile; do
        [ -d "$profile" ] || continue
        chrome_dir="$profile/chrome"
        $DRY_RUN_CMD mkdir -p "$chrome_dir"
        $DRY_RUN_CMD ln -sfn "${materialFoxUserChrome}" "$chrome_dir/userChrome.css"
        $DRY_RUN_CMD ln -sfn "${materialFoxUserContent}" "$chrome_dir/userContent.css"
      done < <(find "$ff_dir" -mindepth 1 -maxdepth 1 -type d -name '*.default*' -print0)
    fi
  '';

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
      plugins = [
        "git"
        "sudo"
      ];
      theme = "robbyrussell";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    studyPlanner
    nerd-fonts.jetbrains-mono
    git
    xournalpp
    affinity-v3
    easyeffects
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
      $DRY_RUN_CMD sed -i \
        -e 's/tokyo-night\.gpl/livara.gpl/g' \
        -e 's|<property name="defaultSaveName" value="[^"]*"/>|<property name="defaultSaveName" value="%F"/>|' \
        "${xournalppLocalConfig}/settings.xml"
    elif [ ! -e "${xournalppLocalConfig}/settings.xml" ]; then
      $DRY_RUN_CMD cp "${xournalppSettings}" "${xournalppLocalConfig}/settings.xml"
    fi
    if [ ! -e "${xournalppLocalConfig}/toolbar.ini" ]; then
      $DRY_RUN_CMD cp "${xournalppToolbar}" "${xournalppLocalConfig}/toolbar.ini"
    fi
    if [ ! -e "${xournalppLocalConfig}/palettes/livara.gpl" ]; then
      $DRY_RUN_CMD mkdir -p "${xournalppLocalConfig}/palettes"
      $DRY_RUN_CMD cp "${xournalppPalette}" "${xournalppLocalConfig}/palettes/livara.gpl"
    fi
  '';
  xdg.configFile."xournalpp/default_template.tex".source =
    "${inputs.xournal-conf}/xournalpp/default_template.tex";

  # Okular: dark document background for comfortable PDF reading.
  # RenderMode=Paper changes ONLY the paper/background color (PaperColor) to
  # a dark grey (#1E1E1E) without inverting text or embedded images — the
  # cleanest dark reading experience.  ChangeColors must be true to activate
  # the render mode.  Keys are defined in okular_core.kcfg [Document] group.
  # See research/okular-dark-background-research.md for full rationale.
  xdg.configFile."okularpartrc".text = ''
    [Document]
    ChangeColors=true
    RenderMode=Paper
    PaperColor=30,30,30
  '';

  # Restore the native Nautilus desktop entry at user priority.
  # DBusActivatable=false keeps launches on the declared executable.
  home.file.".local/share/applications/org.gnome.Nautilus.desktop".text = ''
    [Desktop Entry]
    Name=Files
    Comment=Access and organize files
    Exec=${pkgs.nautilus}/bin/nautilus --new-window %U
    Icon=org.gnome.Nautilus
    Terminal=false
    Type=Application
    StartupNotify=true
    DBusActivatable=false
    Categories=GNOME;GTK;Utility;Core;FileManager;
    MimeType=inode/directory;application/x-7z-compressed;application/zip;application/gzip;
  '';

  xdg.desktopEntries.livara-study-planner = {
    name = "Livara Study Planner";
    genericName = "Study Schedule Planner";
    comment = "Plan reusable study blocks and alternating cycles";
    exec = "${studyPlanner}/bin/livara-study-planner gui";
    terminal = false;
    icon = "x-office-calendar";
    type = "Application";
    categories = [
      "Education"
      "Office"
    ];
  };

  xdg.desktopEntries."com.github.xournalpp.xournalpp" = {
    name = "Xournal++";
    genericName = "Handwritten Notes";
    comment = "Open Xournal++ journals";
    exec = "${pkgs.xournalpp}/bin/xournalpp %F";
    terminal = false;
    icon = "com.github.xournalpp.xournalpp";
    type = "Application";
    mimeType = [ "application/x-xopp" ];
    categories = [
      "Education"
      "Office"
    ];
  };

  xdg.desktopEntries.nvim = {
    name = "Neovim (NixVim)";
    genericName = "Editor";
    comment = "Edit text files";
    exec = "wezterm start --always-new-process -- nvim %F";
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
    categories = [
      "Development"
      "Utility"
      "TextEditor"
    ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "okularApplication_pdf.desktop" ];
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "application/x-xopp" = [ "com.github.xournalpp.xournalpp.desktop" ];
      "text/plain" = [ "nvim.desktop" ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
      # Nautilus is the native GTK/GVFS directory opener.
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    # niri has no desktop-icons concept; suppress the XDG Desktop dir so
    # Home Manager does not create an empty ~/Desktop every activation.
    desktop = null;
    publicShare = null;
    pictures = "${config.home.homeDirectory}/Pictures";
    music = "${config.home.homeDirectory}/Musics";
  };

}
