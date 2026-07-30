{ self, pkgs, ... }: {
  flake.nixosModules.greeter = { pkgs, ... }: {

    services.greetd.enable = true;

    programs.regreet = {
      enable = true;

      # ── Background: Use the Noctalia-themed icon (purple/violet) as wallpaper
      settings.background = {
        path = "${self}/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg";
        fit = "Cover";
      };

      # ── GTK Theme: dark, modern
      settings.GTK = {
        application_prefer_dark_theme = true;
        cursor_theme_name = "Bibata-Modern-Classic";
        cursor_blink = true;
        font_name = "Cantarell 14";
        icon_theme_name = "Adwaita";
        theme_name = "adw-gtk3-dark";
      };

      # ── Clock: compact, 24h
      settings.widget.clock = {
        format = "%H:%M";
        resolution = "500ms";
        label_width = 120;
        locale = "pt_BR";
      };

      # ── Appearance
      settings.appearance.greeting_msg = "Bem-vindo de volta";

      # ── Skip selection: auto-select last user
      settings.skip_selection = false;

      # ── Extra CSS: Noctalia purple/violet theme
      extraCss = ''
        /* ── Noctalia Theme for ReGreet ─────────────────────────── */

        /* Global background - slightly darker than the image to reduce
           glare and ensure text readability */
        window {
          background-color: rgba(10, 10, 18, 0.35);
        }

        /* Main container - frosted glass effect */
        .greeter-container, #window-frame {
          background-color: rgba(15, 15, 25, 0.55);
          border-radius: 16px;
          border: 1px solid rgba(139, 92, 246, 0.15);
          box-shadow: 0 8px 32px rgba(124, 58, 237, 0.1);
        }

        /* Username label */
        .user-label {
          color: #e9d5ff;
          font-size: 18px;
          font-weight: bold;
          text-shadow: 0 2px 8px rgba(124, 58, 237, 0.3);
        }

        /* Username entry field */
        entry {
          background-color: rgba(30, 27, 46, 0.85);
          border: 1px solid rgba(139, 92, 246, 0.25);
          border-radius: 10px;
          color: #f5f3ff;
          padding: 8px 14px;
          font-size: 14px;
          transition: border-color 0.2s ease;
        }

        entry:focus {
          border-color: rgba(139, 92, 246, 0.6);
          box-shadow: 0 0 12px rgba(124, 58, 237, 0.2);
        }

        /* Buttons: rounded, purple-tinted */
        button {
          background-color: rgba(124, 58, 237, 0.2);
          border: 1px solid rgba(139, 92, 246, 0.3);
          border-radius: 10px;
          color: #ddd6fe;
          padding: 6px 16px;
          font-size: 13px;
          transition: all 0.15s ease;
        }

        button:hover {
          background-color: rgba(124, 58, 237, 0.35);
          border-color: rgba(139, 92, 246, 0.5);
          box-shadow: 0 2px 8px rgba(124, 58, 237, 0.15);
        }

        button:active {
          background-color: rgba(124, 58, 237, 0.45);
        }

        /* Suggested action (login button) - more prominent */
        button.suggested-action {
          background-color: rgba(124, 58, 237, 0.4);
          border-color: rgba(139, 92, 246, 0.5);
          font-weight: bold;
        }

        button.suggested-action:hover {
          background-color: rgba(124, 58, 237, 0.55);
          border-color: rgba(139, 92, 246, 0.7);
          box-shadow: 0 4px 16px rgba(124, 58, 237, 0.25);
        }

        /* Session dropdown */
        .session-button {
          background-color: rgba(30, 27, 46, 0.8);
          border-color: rgba(139, 92, 246, 0.2);
        }

        /* User avatars */
        .avatar {
          border: 2px solid rgba(139, 92, 246, 0.3);
          border-radius: 50%;
        }

        /* Error message */
        .error-label {
          color: #fca5a5;
        }

        /* Clock widget */
        .clock-label {
          color: rgba(221, 214, 254, 0.7);
          font-size: 12px;
        }

        /* Combobox / dropdown arrows */
        combobox button {
          background-color: rgba(30, 27, 46, 0.8);
          border-color: rgba(139, 92, 246, 0.2);
        }

        /* Tooltip */
        tooltip {
          background-color: rgba(15, 15, 25, 0.9);
          border-radius: 8px;
          color: #e9d5ff;
        }

        /* Scrollbar */
        scrollbar slider {
          background-color: rgba(139, 92, 246, 0.3);
          border-radius: 4px;
          min-width: 6px;
        }

        scrollbar slider:hover {
          background-color: rgba(139, 92, 246, 0.5);
        }
      '';
    };

    environment.systemPackages = with pkgs; [
      adw-gtk3
      bibata-cursor-theme
      cantarell-fonts
    ];
  };
}
