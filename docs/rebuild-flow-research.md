# Rebuild flow research record

## Findings confirmed from documentation

The Flake Parts Home Manager module exposes `flake.homeModules` and `flake.homeConfigurations`. It must be imported inside the `mkFlake` import list through `inputs.home-manager.flakeModules.home-manager`. The repository previously used the nonstandard `flake.homeManagerModules` output without importing that module, which caused an unknown-output warning; defining it from two feature files then caused the uniqueness error because raw flake outputs are unique unless a typed mergeable option is declared.

The correct local contract is therefore:

```nix
imports = [ inputs.home-manager.flakeModules.home-manager ];

flake.homeModules = {
  hyprland = ...;
  end4 = ...;
};
```

Consumers use `self.homeModules.hyprland` and `self.homeModules.end4` in Home Manager `sharedModules`.

For a Git flake, the source copied into the Nix store is based on the Git worktree and untracked files are not included. A dirty tree warning is not itself an evaluation failure, but a configuration file referenced by the flake must be tracked or otherwise made available through an input/path that Nix can copy. The local `xournalpp/` directory is not referenced by the flake; the profile consumes the `xournal-conf` flake input and only uses the local directory as a runtime synchronization target.

The documented `nixos-rebuild switch` flow evaluates/builds `config.system.build.toplevel`, creates a new system profile generation, updates the bootloader default, and activates the generation. `boot` builds and selects the next boot without activating now; `test` activates without adding a bootloader entry; `build` only builds; `dry-activate` reports activation changes; and `--rollback switch` activates the previous generation without rebuilding.

A safe repository workflow must therefore separate: preserving local changes, fetching/merging the intended revision, updating the lockfile only when explicitly requested, running `nix flake check --no-build`, evaluating the target system derivation, using `nixos-rebuild dry-activate` or `test` before `switch` when the change is high-risk, and retaining a rollback path.

## References

1. [Flake Parts core options](https://flake.parts/options/flake-parts.html)
2. [Flake Parts Home Manager module](https://flake.parts/options/home-manager.html)
3. [Flake Parts modules option](https://flake.parts/options/flake-parts-modules.html)
4. [Official NixOS Wiki: nixos-rebuild](https://wiki.nixos.org/wiki/Nixos-rebuild)
5. [Home Manager manual](https://nix-community.github.io/home-manager/)


## Nix command semantics

The Nix reference distinguishes `nix flake lock` from `nix flake update`: `lock` creates missing entries and does not update entries that are already locked, while `update` updates existing inputs and accepts selected input names. `nix flake check --no-build` still evaluates the flake and verifies the expected output types; it only skips building checks. It evaluates `nixosConfigurations.<name>.config.system.build.toplevel`, so a successful check is a structural/evaluation gate, not proof that activation succeeded. `nix eval --raw` is appropriate for printing a derivation path but does not build or activate it.

References:

6. [Nix Reference: nix flake check](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-check)
7. [Nix Reference: nix flake lock](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-lock)
8. [Nix Reference: nix flake update](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-update)
9. [Nix Reference: nix eval](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-eval)


## Bootstrap and evaluation flags

The official Nix 2.34 reference lists `--no-update-lock-file` under common flake-related options for `nix develop`, `nix flake check`, and `nix eval`. The installer can therefore pass the flag during development-shell bootstrap and evaluation gates to prevent implicit lockfile changes. The same reference documents that `nix flake check --no-build` evaluates the flake and checks output types while skipping builds, whereas `nix eval --raw` evaluates an expression and prints its string result. These commands are necessary gates but do not replace a build or activation test.

References:

10. [Nix Reference: nix develop](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-develop)
11. [Nix Reference: nix flake check](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-check)
12. [Nix Reference: nix eval](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-eval)

## Runtime findings from the first real installer run

The first real `NIX_CONF_REBUILD_MODE=test ./install.sh` run exposed two installer defects that static checks could not catch:

1. The evaluator used `$flake#latitude.config...`. A flake reference must include the output namespace, so the correct installable is `$flake#nixosConfigurations.latitude.config.system.build.toplevel.drvPath`, with the host selected dynamically. The Nix reference describes `nix eval` as accepting an installable and resolving an attribute path within the flake; the NixOS system is under the `nixosConfigurations` output.[13]
2. The hardware generator combined `findmnt --list` and `--raw`. The util-linux manual documents both as output-format selectors; the local util-linux version rejects their combination. The stable scripted form is `findmnt --kernel --noheadings --raw --output TARGET,SOURCE,FSTYPE,OPTIONS`, followed by explicit field parsing.[14]

Both defects were corrected and regression-tested. The mock installer test now asserts the complete `nixosConfigurations.<host>` path, while the sandbox executes the exact `findmnt` command and verifies that mount records are produced.

The operational implication is important: `nix flake check` can pass while an installer-owned `nix eval` command is still malformed, because `flake check` validates the flake's declared outputs rather than arbitrary attribute paths assembled by shell code. The installer therefore needs its own gate test, and that test must run before `nixos-rebuild`.

13. [Nix Reference: nix eval](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-eval)
14. [findmnt(8) Linux manual](https://man7.org/linux/man-pages/man8/findmnt.8.html)

## QuickShell/Qt build failure

The real build failed while compiling QuickShell 0.2.0, before any NixOS activation. The dependency chain was `quickshell -> quickshell-wrapped -> home-manager-path -> home-manager-generation -> user-environment -> etc -> nixos-system`; the root cause was the CMake target `Qt6::WaylandClientPrivate` being absent, not a service or hardware problem.

The QuickShell upstream CMake intentionally links `Qt6::WaylandClientPrivate` for generated Wayland protocol modules and calls `Qt6::qtwaylandscanner`. The official installation guide states that the embedded QuickShell flake must follow the same nixpkgs as the host because mismatched system dependencies can cause crashes and other issues. It also documents `quickshell.packages.<system>.default` as the supported flake package.[15] [16]

A closely related nixpkgs failure was fixed upstream by correcting the Qt6 `find_package` handling in the affected CMake project, confirming that this class of error is generally a Qt package integration/version issue rather than a missing runtime package.[17]

The current nix-conf uses the QuickShell `master` flake with `inputs.nixpkgs.follows = "nixpkgs"`, while the failing derivation is version 0.2.0. The next correction must therefore verify the locked QuickShell revision and its Qt dependency graph, prefer a compatible tagged release or a known-good upstream revision, and avoid adding arbitrary Qt packages only to make CMake appear to configure. The end-4 module currently adds Qt runtime packages to `home.packages`, but that cannot repair a missing CMake imported target in the QuickShell build derivation itself.

15. [QuickShell installation and setup](https://quickshell.org/docs/v0.3.0/guide/install-setup/)
16. [QuickShell Wayland CMake integration](https://github.com/quickshell-mirror/quickshell/blob/master/src/wayland/CMakeLists.txt)
17. [Nixpkgs PR #455451: upstream Qt6 find_package fix](https://github.com/NixOS/nixpkgs/pull/455451)

The release comparison identified the precise compatibility fix. QuickShell v0.2.0 always placed `qt6.qtwayland` in `buildInputs`; its package therefore fails against the Qt 6.10 layout used by the current nixpkgs revision, where CMake does not expose the expected `Qt6::WaylandClientPrivate` imported target in that configuration. QuickShell v0.3.0 updates its Nix expression: it keeps `qt6.qtwayland` as a native build dependency for the Wayland scanner, but only adds it to runtime `buildInputs` when `qt6.qtbase.version < 6.10.0`. The project is therefore pinned to the upstream `v0.3.0` tag rather than applying an ad-hoc local CMake patch.

The end-4 QML source uses standard `Quickshell`, `Quickshell.Wayland`, `Quickshell.Hyprland`, `Quickshell.Widgets`, and service modules without an explicit 0.2-only API declaration in the audited tree. This makes the v0.3.0 tag the supported compatibility upgrade for the current dotfiles revision. The lockfile must be regenerated for the changed tag; it must not be hand-edited with an invented NAR hash.

18. [QuickShell v0.2.0 package expression](https://git.outfoxxed.me/quickshell/quickshell/raw/tag/v0.2.0/default.nix)
19. [QuickShell v0.3.0 package expression](https://git.outfoxxed.me/quickshell/quickshell/raw/tag/v0.3.0/default.nix)
20. [Nix Archive format](https://nix.dev/manual/nix/2.22/protocols/nix-archive)

## Git tag reference correction

The laptop exposed a second, distinct failure after the QuickShell release fix: `ref=v0.3.0` was resolved as `refs/heads/v0.3.0`, but the upstream repository publishes `v0.3.0` as a tag. Nix's Git flake behavior has a documented history around this distinction; a bare `ref` is not a reliable tag selector for this remote/backend. The robust solution is to use the immutable commit in the flake URL (`rev=59e9c47b0eb48a9e4bcf9631fa062ee939bd2e83`) and retain the tag as a human-readable comment/documentation reference, or explicitly use `ref=refs/tags/v0.3.0` only if the backend accepts the fully qualified tag ref. The immutable revision avoids branch/tag namespace ambiguity and makes the source reproducible.

21. [Nix issue: Git flake `ref` behavior](https://github.com/NixOS/nix/issues/8790)
22. [Nix manual: `builtins.fetchGit`](https://nix.dev/manual/nix/2.28/language/builtins.html)
23. [Nix discourse: Git tags in flake inputs](https://discourse.nixos.org/t/git-tags-in-flakes-inputs/25511)

## wf-recorder / FFmpeg build failure

The real build reached Home Manager package closure construction and failed while compiling `wf-recorder-0.6.0`; it did not reach activation. The compiler error is the removed `AVCodec::sample_fmts` field. Upstream packaging work for newer FFmpeg replaces direct access to `pix_fmts`, `ch_layouts`, and `sample_fmts` with `avcodec_get_supported_config`, confirming an FFmpeg API compatibility break rather than a NixOS service or hardware issue.[24] The nixpkgs package remains a standalone wlroots screen recorder.[25]

This configuration implements screenshots with `grim`, `slurp`, `satty`, and `grimblast`; the active screenshot bindings do not require `wf-recorder`. The safest architecture is to remove `wf-recorder` from the runtime closure rather than add an unreviewed FFmpeg override or carry a local C++ patch. The optional end-4 recording entry point is preserved through a local wrapper around `gpu-screen-recorder`, whose package is maintained separately from the broken wf-recorder build and must be tested on the Latitude Intel/VAAPI stack.

24. [FreeBSD ports: wf-recorder FFmpeg 9 compatibility patch](https://cgit.freebsd.org/ports/commit/?id=09573f914766a0bc86a694c47aeeef7776757dc9)
25. [MyNixOS: wf-recorder package](https://mynixos.com/nixpkgs/package/wf-recorder)
26. [wf-recorder upstream README](https://github.com/ammen99/wf-recorder)

## Recording alternatives

The NixOS Wiki documents `gpu-screen-recorder` as a GPU-based Wayland recorder with H.264/HEVC/AV1 and Opus/AAC/FLAC support, and nixpkgs provides a package with PipeWire and Wayland support.[27] The current Hyprland documentation still lists wf-recorder for simple wlroots recording, but the local nixpkgs build is broken against the selected FFmpeg API.[28] The active configuration therefore removes wf-recorder and uses a small local gpu-screen-recorder wrapper for the optional recording script. Screenshots remain independent of this recorder and continue to use grim/grimblast/slurp/satty.

27. [Official NixOS Wiki: gpu-screen-recorder](https://wiki.nixos.org/wiki/Gpu-screen-recorder)
28. [Hyprland Wiki: Screenshots and Recording](https://wiki.hypr.land/Useful-Utilities/Screenshots-and-Recording/)

The gpu-screen-recorder CLI supports `-w region -region WxH+X+Y` for region capture, `-w screen` or a monitor name for fullscreen capture, `-a default_output` for audio, and SIGINT for a clean stop. The local wrapper selects the focused Hyprland monitor through `hyprctl monitors -j`, uses `slurp -f '%wx%h+%x+%y'` for region selection, and writes MP4 files under the user's Videos directory. These options are documented in the Debian manpage and upstream README mirrors.[29] [30]

29. [Debian gpu-screen-recorder manpage](https://manpages.debian.org/testing/gpu-screen-recorder-cli/gpu-screen-recorder.1.en.html)
30. [GPU Screen Recorder upstream README](https://git.dec05eba.com/gpu-screen-recorder/about/)

## Hyprland Lua configuration failure

Hyprland 0.55+ prefers Lua when `$XDG_CONFIG_HOME/hypr/hyprland.lua` exists, and a fundamental Lua syntax error prevents later bindings in the same file from loading; Hyprland then exposes emergency bindings such as Super+Q, Super+R, and Super+M. The official migration note says that a `hyprland.lua` file takes precedence over the legacy `hyprland.conf` file at startup: https://hypr.land/news/26_lua/ and https://wiki.hypr.land/Configuring/Start/.

Home Manager issue #9468 reproduces the exact error `/home/.../hyprland.lua:5: <name> expected near '$'` when `wayland.windowManager.hyprland.configType = "lua"` is combined with legacy hyprlang-style settings. The maintainer explains that Lua configuration requires Lua syntax rather than the legacy settings representation: https://github.com/nix-community/home-manager/issues/9468.

The previous end-4 assets integrated in this repository were `.conf` fragments and used hyprlang syntax, but the selected official end-4 revision is a native Lua tree. The current adapter therefore sets `configType = "lua"`, injects the official `hyprland.lua` entrypoint through `extraConfig`, adds the official module directories to Lua's `package.path`, and installs the modules with `extraLuaFiles` using `autoLoad = false`. This preserves the upstream require order and prevents Home Manager from inserting legacy hyprlang text into a Lua file. A stale user `hyprland.lua` that contains hyprlang assignments is backed up and removed during activation; a valid generated Lua configuration is not removed.

The earlier error with more than one thousand missing `general.conf`-style paths was therefore not an icon or plugin problem. It was a source-version mismatch: the composition referenced the old third-party `tmp` tree while the runtime and Home Manager path expected the current Lua contract. The lockfile now pins `end-4/dots-hyprland` directly at an immutable revision, and the integration checks the source paths before the user runs the Nix evaluation gate.

The current Home Manager Lua renderer does not insert `hl.config({ autogenerated = true })`. The activation hook therefore detects that marker, as well as legacy hyprlang assignments, backs up the regular file, and removes it before Home Manager writes the managed Lua configuration. It does not delete a valid Lua file or a Home Manager symlink. If the warning remains, inspect the active file's symlink target and the Home Manager activation service before deleting anything.

Runtime changes made in the end-4 settings UI are not Nix expressions. The supported bridge is `scripts/sync-end4-state.sh`: `export` validates and copies selected user-owned settings into `home/livara/end4-state`, while `import` restores them with a timestamped backup. Matugen output and QuickShell caches remain derived state and are deliberately excluded.

Serpantinum was reviewed separately and not adopted. Its current personal NixOS tree assumes `/etc/nixos/config`, host-specific hardware, hyprlang `.conf` files, and imperative `rsync` activation. Importing it directly would recreate the format and ownership conflicts described above. See `docs/serpantinum-evaluation.md` for the source-by-source decision record.


## UWSM session and initial end-4 colors

The NixOS Hyprland module remains the owner of session startup with `programs.hyprland.withUWSM = true`, while Home Manager keeps `wayland.windowManager.hyprland.systemd.enable = false`. The SDDM default is forced to `hyprland-uwsm`, the desktop entry generated by NixOS for the UWSM-managed session. The end-4 runtime seed now runs after Home Manager `linkGeneration` and creates the writable fallback `~/.config/hypr/hyprland/colors.lua` before the compositor can require `hyprland.colors`. Matugen may replace this fallback after the first wallpaper selection.


## Legacy Lua migration hook quoting

The legacy Hyprland Lua migration hook must not use a shell regex containing nested single- and double-quote fragments. Home Manager embeds the activation body into a generated shell script, and that quoting pattern produced a syntax error during activation. The hook now performs independent fixed-string checks for `require("hyprland.shell")` and `require('hyprland.shell')`, followed by simple regular-expression checks for the remaining legacy markers.

Validation includes evaluating the activation hook with Nix, extracting its generated `data` field, running `bash -n` on that exact script, and exercising both legacy-file archival and valid-Lua preservation in a temporary home directory.
