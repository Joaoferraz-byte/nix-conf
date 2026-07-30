# ─── Dell Latitude 5410 Configuration ─────────────────────────────────────
# Specs: Intel Core i5-10310U (10th gen), 16GB RAM, 256GB SSD,
#        Intel UHD Graphics (integrated), 14" FHD display
#
# NOTE: UUIDs de disco e partições devem ser atualizados após a instalação.
# Este arquivo serve como template; após o `nixos-generate-config` na
# máquina real, copie os UUIDs para o hardware.nix.
{ self, ... }: {
  flake.nixosModules.dellLatitude5410Configuration = { pkgs, lib, ... }: {
    imports = [
      self.nixosModules.dellLatitude5410Hardware
      self.nixosModules.commonPackages
      self.nixosModules.hyprland
      self.nixosModules.greeter
      self.nixosModules.desktop-portals
      self.nixosModules.flatpak
      self.nixosModules.audiorelay
      self.nixosModules.keyd
      self.nixosModules.system-hardening
      # Migrado de quickshell para ambxst (BUG-002).
      # O módulo ambxst.nix gerencia o Ambxst shell com suporte completo
      # a fontes, upower, power-profiles-daemon e módulo HM.
      self.nixosModules.ambxst
    ];
    # ── Boot ──────────────────────────────────────────────────────────────
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    # Kernel padrão (sem Zen, mais estável para laptop corporativo)
    boot.kernelPackages = pkgs.linuxPackages;
    # ── Rede ──────────────────────────────────────────────────────────────
    networking.hostName = "limine-laptop";
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
    # ── Energia ────────────────────────────────────────────────────────────
    # O Dell Latitude 5410 usa tlp (laptop), que conflita com power-profiles-daemon.
    # O ambxst.nix define power-profiles-daemon.enable = mkDefault true, então
    # forçamos false aqui para manter o tlp.
    services.power-profiles-daemon.enable = lib.mkForce false;

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
