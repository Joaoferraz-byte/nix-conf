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

## Second log

After the Kirigami-related change, the new fatal error is:

`Failed to load configuration ... MaterialShape.qml[1:1]: module "qs.modules.common.widgets.shapes" is not installed`

This is an internal end-4 QML module, not a KDE or Qt module. The failure occurs through `WeatherWidget -> MaterialShape -> IllogicalImpulseFamily`, so adding another system package is not the correct fix. The adapter must ensure that the `common/widgets/shapes` directory is materialized with a valid `qmldir` module declaration, or that the upstream source tree is copied without dropping that module metadata.

## Root cause confirmation and keyboard references

The official illogical-impulse troubleshooting guide identifies this exact internal import failure as a missing Git submodule and recommends cloning with submodules or running `git submodule update --init --recursive`.[1] The official `.gitmodules` maps the missing directory to `end-4/rounded-polygon-qmljs`.[2] The pinned source contains the directory but Nix fetched it empty because the flake input did not request Git submodules.

For the 60% keyboard function layer, `wtype` supports named key presses using `wtype -k <Key>`, including XKB names such as `Left` and function keys.[3]

[1]: https://ii.clsty.link/en/ii-qs/04troubleshooting/ "illogical-impulse Troubleshooting/FAQ"
[2]: https://github.com/end-4/dots-hyprland/blob/main/.gitmodules "end-4/dots-hyprland .gitmodules"
[3]: https://github.com/atx/wtype "atx/wtype"
