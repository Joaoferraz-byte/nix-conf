{ self, ... }: {
  flake.nixosModules.myMachineConfiguration = { pkgs, ... }: {
    imports = [
      self.nixosModules.myMachineHardware
      self.nixosModules.commonPackages
      self.nixosModules.niri
      self.nixosModules.nvidia
      self.nixosModules.greeter
      self.nixosModules.desktop-portals
      self.nixosModules.flatpak
      self.nixosModules.audiorelay
      self.nixosModules.keyd
      self.nixosModules.system-hardening
      # Ambxst substitui o módulo quickshell anterior.
      # O módulo ambxst.nix gerencia:
      #   - O pacote "ambxst" (wrapper Nix com Quickshell + axctl)
      #   - As fontes necessárias (Phosphor Icons, Roboto, Noto, etc.)
      #   - O módulo HM que copia os JSONs de configuração
      self.nixosModules.ambxst
    ];
    # ── Boot ──────────────────────────────────────────────────────────────
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.kernelPackages = pkgs.linuxPackages_zen;
    # ── Rede ──────────────────────────────────────────────────────────────
    networking.hostName = "limine";
    networking.networkmanager.enable = true;
    # ── Local ─────────────────────────────────────────────────────────────
    time.timeZone = "America/Sao_Paulo";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS        = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT    = "pt_BR.UTF-8";
      LC_MONETARY       = "pt_BR.UTF-8";
      LC_NAME           = "pt_BR.UTF-8";
      LC_NUMERIC        = "pt_BR.UTF-8";
      LC_PAPER          = "pt_BR.UTF-8";
      LC_TELEPHONE      = "pt_BR.UTF-8";
      LC_TIME           = "pt_BR.UTF-8";
    };
    services.xserver.xkb = {
      layout  = "br";
      variant = "";
    };
    console.keyMap = "br-abnt2";
    # ── Usuário ───────────────────────────────────────────────────────────
    users.users."livara" = {
      isNormalUser = true;
      description  = "Livara";
      extraGroups  = [ "networkmanager" "wheel" ];
      shell        = pkgs.zsh;
    };
    programs.zsh.enable = true;
    # ── Nix ───────────────────────────────────────────────────────────────
    # experimental-features movido para system-hardening.nix (DRY)
    system.stateVersion = "26.11";
  };
}
