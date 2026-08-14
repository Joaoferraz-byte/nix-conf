# QuickShell Kirigami diagnosis

The uploaded QuickShell log shows a deterministic startup failure, not a dead IPC service:

`Failed to load configuration ... AppIcon.qml[2:1]: module "org.kde.kirigami" is not installed`

The failure propagates through `AppIcon`, `Workspaces`, `BarContent`, `Bar`, and `IllogicalImpulseFamily`, so no bar or visual shell can be created. The log contains many QML intercept lines because QuickShell scans the profile before reporting the fatal missing module.

The current NixOS adapter installs several Qt packages but does not include the KDE Kirigami QML package. The likely declarative fix is to add `kdePackages.kirigami` to the Home Manager package set, then validate that the resulting QuickShell process can resolve `org.kde.kirigami`.

References:

1. NixOS Discourse, “Shell.nix for KDE Kirigami development”: https://discourse.nixos.org/t/shell-nix-for-kde-kirigami-development/14011
2. KDE Community, “Module org.kde.kirigami is not installed”: https://discuss.kde.org/t/module-org-kde-kirigami-is-not-installed/1233
3. end-4/dots-hyprland Discussion #1093, “illogical-impulse on NixOS”: https://github.com/end-4/dots-hyprland/discussions/1093
4. QuickShell installation and setup: https://quickshell.org/docs/v0.3.0/guide/install-setup/
