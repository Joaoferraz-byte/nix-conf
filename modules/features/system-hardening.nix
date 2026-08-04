# ─── System Hardening & Security Module ────────────────────────────────────
# Based on: NixOS Wiki Security, Discourse discussions, Reddit best practices,
# and kernel hardening guides (madaidan's Insecurities, Solene's Harden NixOS).
# Designed for a desktop/workstation use case, balancing security with usability.
{ ... }: {
  flake.nixosModules.system-hardening = { pkgs, lib, ... }: {

    # ── Firewall ──────────────────────────────────────────────────────────
    networking.firewall = {
      enable = true;

      # AudioRelay requires TCP port 59100 open for audio streaming
      allowedTCPPorts = [ 59100 ];

      # Allow mDNS (used by Avahi, local discovery)
      allowedUDPPorts = [ 5353 ];

      # Allow ICMP ping (useful for debugging, not a security risk)
      allowPing = true;

      # Enable connection tracking for stateful inspection
      extraCommands = ''
        iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
      '';
    };

    # ── Kernel Hardening ──────────────────────────────────────────────────
    security.protectKernelImage = true;

    boot.kernel.sysctl = {
      # Restrict ptrace: level 2 for desktop (blocks non-child debugging)
      # Source: Reddit r/NixOS kernel hardening thread — level 2 recommended
      # for desktops that still need dmesg access (unlike servers that use 3).
      "kernel.yama.ptrace_scope" = 2;

      # Block unprivileged BPF (attack vector via JIT spray)
      # Source: Reddit r/NixOS "kernel hardening + auditd" post (xmrah, 2025)
      "kernel.unprivileged_bpf_disabled" = 1;

      # Restrict access to /proc/sysrq-trigger
      "kernel.sysrq" = 0;

      # Hide kernel pointers (hardens against kernel exploits)
      # Source: Reddit r/NixOS kernel hardening thread
      "kernel.kptr_restrict" = 1;

      # Protect against SYN floods
      "net.ipv4.tcp_syncookies" = 1;

      # Disable source routing
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;

      # Disable ICMP redirects (prevent MITM via routing)
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;

      # Disable IP forwarding (this is a workstation, not a router)
      "net.ipv4.ip_forward" = 0;
      "net.ipv6.conf.all.forwarding" = 0;

      # Log suspicious packets
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;

      # Restrict core dumps from SUID programs
      "fs.suid_dumpable" = 0;

      # Prevent ASLR weakening
      "kernel.randomize_va_space" = 2;

      # Restrict BPF JIT (reduce attack surface)
      "net.core.bpf_jit_harden" = 2;
    };

    # ── Boot Security ─────────────────────────────────────────────────────
    # NOTE: boot.loader.* and boot.kernelModules are host-specific decisions
    # (nvidia vs intel, systemd-boot vs grub) and must be set in the host
    # configuration.nix, not in this shared hardening module.
    # kernelParams for hardening are kept here as they apply to all systems.
    boot.loader.systemd-boot.editor = false; # Prevent editing boot entries

    boot.kernelParams = [
      "mitigations=auto"
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
    ];

    # ── Sudo Hardening ────────────────────────────────────────────────────
    security.sudo = {
      execWheelOnly = true;

      # pwfeedback: show asterisks when typing password
      # Source: Reddit r/NixOS "nice snippets" thread (Maskdask)
      extraConfig = ''
        Defaults pwfeedback
      '';

      extraRules = [{
        users = [ "livara" ];
        commands = [
          { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        ];
      }];
    };

    # ── Privacy & Location Services ───────────────────────────────────────
    # geoclue2 is required for DankMaterialShell's night light (matugen) functionality.
    services.geoclue2.enable = true;

    # ── Auditd with Smart Filtering ───────────────────────────────────────
    # Source: Reddit r/NixOS "kernel hardening + auditd" post (xmrah, 2025).
    # Uses "lock" mode to prevent root from wiping audit rules.
    # Filters by auid>=1000 to ignore systemd/dbus noise.
    security.audit = {
      enable = "lock";
      rules = [
        # Only log access denied events from real users (uid >= 1000)
        "-a always,exit -F arch=b64 -S open,openat -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access_denied"
        "-a always,exit -F arch=b64 -S open,openat -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access_denied"
        # Watch critical system config files
        "-w /etc/sudoers -p wa -k sudoers_changes"
        "-w /etc/ssh/sshd_config -p wa -k sshd_config"
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
      ];
      backlogLimit = 8192; # Prevent log drops under heavy syscall bursts
    };

    # ── Nix Store Security ────────────────────────────────────────────────
    nix = {
      settings = {
        auto-optimise-store = true;
        # Habilita nix-command e flakes para todos os hosts (DRY — evita duplicação em cada configuration.nix)
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" "livara" ];
        allow-import-from-derivation = false;
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 20d";
      };
    };

    # ── Memory Protection ─────────────────────────────────────────────────
    zramSwap = {
      enable = true;
      memoryPercent = 50;
      algorithm = "zstd";
    };

    # ── Systemd Service Hardening ─────────────────────────────────────────
    systemd.services.systemd-resolved.serviceConfig = {
      PrivateDevices = "yes";
      ProtectHome = "yes";
      ProtectSystem = "full";
      NoNewPrivileges = "yes";
    };

    # ── Log Retention ─────────────────────────────────────────────────────
    # Source: Reddit r/NixOS kernel hardening thread — Seal=yes enables
    # systemd's Forward Secure Sealing (FSS) for tamper-proof journal logs.
    services.journald.extraConfig = ''
      SystemMaxUse=200M
      MaxRetentionSec=30day
      Compress=yes
      Seal=yes
    '';
  };
}
