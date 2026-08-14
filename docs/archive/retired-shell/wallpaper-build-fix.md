# Historical SDDM wallpaper build failure

This note records the historical SDDM wallpaper failure and the store-backed asset fix. The active desktop shell is now Hyprland with UWSM and end-4 QuickShell; this document is retained as a troubleshooting record for the SDDM greeter assets.

## Symptom

A previous SilentSDDM migration failed during a system build with an error similar to:

```text
warning: Git tree '/home/livara/.config/nixos' is dirty
cp: cannot stat '.../source/Wallpapers/wallhaven-9or3zx.jpg': No such file or directory
```

The failing dependency chain was `silent-unknown -> sddm.conf -> system-path -> nixos-system`. The build attempted to copy a wallpaper from a direct filesystem path that was not present in the flake source available to the derivation.

## Root cause

The older Pixie-SDDM integration first created a derivation containing the avatar and wallpaper and then passed store paths to the theme. The SilentSDDM integration instead passed a direct path derived from the working tree. A dirty or incomplete Git tree can therefore make the asset unavailable during evaluation or build.

Nix flakes do not treat arbitrary untracked files as part of the Git source. A file can be unavailable when it is untracked, deleted locally, absent because the clone is stale, or referenced through a path that is not copied into the store. The warning that a Git tree is dirty is not itself an error, but it is a useful signal that the evaluated source may differ from the committed tree.

## Robust asset pattern

The greeter module uses a derivation intermediary for assets that must be available in the Nix store:

```nix
{ self, pkgs, ... }:
let
  assets = pkgs.runCommandNoCC "nix-conf-sddm-assets" {} ''
    mkdir -p "$out/backgrounds" "$out/icons"
    cp ${self.outPath + "/Wallpapers/wallhaven-9or3zx.jpg"} "$out/backgrounds/wallhaven-9or3zx.jpg"
    cp ${self.outPath + "/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg"} "$out/icons/avatar.jpg"
  '';
in {
  programs.silentSDDM = {
    backgrounds."wallhaven-9or3zx.jpg" = assets + "/backgrounds/wallhaven-9or3zx.jpg";
    profileIcons.livara = assets + "/icons/avatar.jpg";
  };
}
```

The important invariant is that the greeter receives store-backed paths, not a mutable home-directory or checkout path. Runtime-generated end-4 wallpapers and Matugen outputs follow a different contract: they remain writable under the user state directories and must not be symlinked into the Nix store.

## Current verification flow

Run the repository installer as the checkout owner. It checks Git permissions, conflict state, hardware, flake evaluation, and the selected system derivation before invoking `nixos-rebuild`:

```bash
cd ~/.config/nixos
NIX_CONF_HOST=myMachine NIX_CONF_REBUILD_MODE=dry-activate ./install.sh
NIX_CONF_HOST=myMachine NIX_CONF_REBUILD_MODE=test ./install.sh
NIX_CONF_HOST=myMachine ./install.sh
```

If a wallpaper asset is intentionally changed, confirm that it is present and tracked before the build:

```bash
cd ~/.config/nixos
git ls-files --error-unmatch Wallpapers Icons
git diff --check
nix flake check --no-build --no-update-lock-file --show-trace
```

Do not solve missing assets by disabling the flake source filter, copying an entire mutable configuration tree into the store, or adding unrelated ACPI parameters. Resolve the source path or tracking problem at its origin.

## Recovery

If activation fails, retain the rebuild log and inspect system generations:

```bash
tail -n 100 /tmp/nixos-rebuild.log
sudo nixos-rebuild list-generations
sudo nixos-rebuild --rollback switch
```

## References

1. [NixOS flake documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake)
2. [SilentSDDM](https://github.com/uiriansan/SilentSDDM)
3. [nix-conf](https://github.com/Joaoferraz-byte/nix-conf)
