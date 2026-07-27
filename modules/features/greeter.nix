{ ... }: {
  flake.nixosModules.greeter = { pkgs, ... }: {
    services.greetd.enable = true;

    programs.regreet = {
      enable = true;

      theme.name = "adw-gtk3-dark";
      cursorTheme.name = "Bibata-Modern-Classic";
      font = {
        name = "Cantarell";
        size = 13;
      };

      extraCss = ''
        window {
          background-color: #1e1e2e;
        }
        .greeter-container, #window-frame {
          background-color: #1e1e2e;
        }
        button, entry {
          border-radius: 8px;
        }
        button:hover, entry:focus {
          border-color: #7fc8ff;
        }
      '';
    };

    environment.systemPackages = with pkgs; [ adw-gtk3 ];
  };
}
