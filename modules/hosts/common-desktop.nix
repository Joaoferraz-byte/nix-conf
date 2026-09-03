{ self, inputs, ... }:
{
  flake.nixosModules.commonDesktop = { config, lib, ... }:
    let
      cfg = config.desktop.profile;
    in
    {
      imports = [
        self.nixosModules.appimage
        self.nixosModules.firejail
        self.nixosModules.niri
        inputs.stylix.nixosModules.stylix
        inputs.home-manager.nixosModules.home-manager
      ];

      options.desktop.profile.compositor = lib.mkOption {
        type = lib.types.enum [ "niri" ];
        default = "niri";
        description = "Wayland compositor/session used by the desktop profile.";
      };

      options.desktop.profile.userName = lib.mkOption {
        type = lib.types.str;
        default = "livara";
        description = "Home Manager user that owns the desktop profile.";
      };

      options.desktop.profile.monitorProfile = lib.mkOption {
        type = lib.types.enum [ "latitude" "myMachine" ];
        default = "myMachine";
        description = "Named monitor policy consumed by the Home Manager adapter.";
      };

      options.desktop.profile.keyboardLayout = lib.mkOption {
        type = lib.types.str;
        default = "br";
        description = "Global XKB layout applied by niri to every keyboard device.";
      };

      options.desktop.profile.keyboardVariant = lib.mkOption {
        type = lib.types.str;
        default = "abnt2";
        description = "Global XKB variant applied by niri to every keyboard device.";
      };

      options.desktop.profile.consoleKeyMap = lib.mkOption {
        type = lib.types.str;
        default = "br-abnt2";
        description = "Linux console keymap matching the built-in keyboard.";
      };


      config = {
        networking.nameservers = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        programs.dconf.enable = true;
        services.gvfs.enable = true;
        services.udisks2.enable = true;

        # Shared overlays applied to every host importing commonDesktop.
        nixpkgs.overlays = [
          inputs.affinity-nix.overlays.default
          (final: prev: {
            libdisplay-info_0_2 = final.libdisplay-info;
            # gradience was removed from nixpkgs; no-op compatibility command.
            gradience = prev.writeShellScriptBin "gradience" ''
              echo "gradience was removed from nixpkgs; using a no-op compatibility command." >&2
            '';
            # Nautilus' upstream bookmark model does not expose a declarative
            # per-bookmark symbolic icon. The small local patch reads the
            # session-owned URI -> icon map and changes only symbolic-icon.
            nautilus = prev.nautilus.overrideAttrs (old: {
              patches = (old.patches or []) ++ [ ../packages/nautilus-bookmark-icons.patch ];
            });
          })
        ];

        environment.sessionVariables = {
          XKB_DEFAULT_MODEL = "pc105";
          XKB_DEFAULT_RULES = "evdev";
          XKB_DEFAULT_LAYOUT = cfg.keyboardLayout;
          XKB_DEFAULT_VARIANT = cfg.keyboardVariant;
          XKB_DEFAULT_OPTIONS = "";
          GTK_ICON_THEME = "Livara-Kora";
          QT_ICON_THEME = "Livara-Kora";
        };

        services.xserver.xkb = {
          model = "pc105";
          layout = cfg.keyboardLayout;
          variant = cfg.keyboardVariant;
          options = "";
        };

        # The console keymap is separate from the niri/XKB session layer.
        console.keyMap = cfg.consoleKeyMap;

        services.displayManager.defaultSession = lib.mkForce "niri";

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          # Noctalia and plugins retain mutable runtime state under XDG_STATE_HOME.
          # Keep one rolling Home Manager backup and replace it atomically on
          # later activations instead of aborting when .backup already exists.
          backupFileExtension = "backup";
          overwriteBackup = true;
          extraSpecialArgs = {
            inherit inputs self;
            userName = cfg.userName;
            desktopProfile = cfg;
          };
          sharedModules = [
            inputs.stylix.homeModules.stylix
            inputs.shell-conf.homeModules.support
            inputs.nixvim.homeModules.nixvim
            inputs.spicetify-nix.homeManagerModules.default
          ];
          users.${cfg.userName} = import ../../home/livara/home.nix;
        };
      };
    };
}
