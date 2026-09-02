## Scope

`nix-conf` is the declarative composition root for NixOS hosts. flake-parts publishes system configurations and feature modules by domain; Home Manager composes the user environment; external inputs provide specialized modules. The graphical session has a single compositor and a single visual shell.

> **One owner per concern, one explicit closure per service, and a public contract between repositories.**

NixOS owns Niri, system XKB, keyd, portals, drivers, networking, audio and privileged services. Home Manager owns user programs, XDG files and user-level services. `noctalia-conf` owns the pinned Noctalia runtime and its local lifecycle policy. `shell-conf` owns the visual shell policy, launcher, panels, notifications, local wallpaper selection, palette templates, reviewed plugins, IPC adapters and shell-independent user support. `vim-conf` owns NixVim; `xournal-conf` owns Xournal++ editable files; `Wallpapers` remains a local image catalog rather than a synchronized runtime repository.

## Composition flow

```text
flake inputs
  → flake-parts feature modules
    → host roots
      → common desktop profile
        → Home Manager user profile
          → Niri config + Noctalia module + application-support module
```

Composition passes only the necessary integration data through `extraSpecialArgs` (`inputs`, user, and typed profile). The compositor is not passed as a flag to the shell: the profile accepts only `niri`, and UI actions are expressed as native Niri actions or documented Noctalia v5 IPC.

| Host | Primary layout | Output policy |
|---|---|---|
| `latitude` | `ie` on internal keyboard; Aitek external handled by keyd | Declarative scale for `desc:BOE 0x07BB` panel. |
| `myMachine` | `br(abnt2)` | Dynamic discovery; empty `outputs.kdl`. |

## Repository boundaries

| Repository/input | Public contract | Owner |
|---|---|---|
| `nix-conf` | Hosts, NixOS modules, Home Manager composition, session policy | System and integration |
| `noctalia-conf` | `packages.default`, `overlays.default`, `homeModules.default` and pinned upstream runtime | Noctalia runtime |
| `shell-conf` | `homeModules.default`/`support`, Noctalia TOML, templates, plugins, adapters and user support | Visual shell and user integration |
| `vim-conf` | NixVim module, plugins and keymaps | Editor |
| `xournal-conf` | Xournal++ XML, INI, TeX and defaults | Notes application |
| `Wallpapers` | Images | Asset catalog |

`noctalia-conf` pins the upstream Noctalia runtime and exposes the local lifecycle contract. `shell-conf` pins the community templates and owns the curated Noctalia integration without writing compositor configuration. The `nix-conf` flake does not import a Hyprland module.

## Niri and Noctalia session

`modules/features/niri.nix` enables Niri and the minimal Wayland environment packages. `home/livara/niri.nix` is the sole owner of `~/.config/niri/config.kdl`, navigation, workspaces, fullscreen, screenshot, hardware keys and Noctalia IPC binds. `home/livara/monitors.nix` materializes only `outputs.kdl` and never declares a fictitious monitor.

Niri starts exactly one Noctalia process through `spawn-at-startup`; the Home Manager service is disabled to avoid a duplicate lifecycle. The visual surface does not consult `hyprctl`, does not embed bar QML and does not start a second shell. Niri includes an optional runtime color file generated from the Noctalia wallpaper palette; because included files are watched, a wallpaper change updates the focus-ring colors without editing the declarative compositor file.

| Concern | Owner |
|---|---|
| Login and compositor | NixOS Niri + display manager |
| Input/XKB and specific remapping | NixOS XKB + keyd |
| Idle/lock/monitor power | Noctalia v5 session policy |
| Bar, panels, launcher and wallpaper picker | Noctalia v5 |
| Wallpaper catalog | Local `~/Wallpapers` + Noctalia wallpaper automation |
| Dynamic theme generation | Noctalia v5 palette and user templates |
| Niri focus-ring and border colors | `shell-conf` Niri user template + optional `~/.config/niri/noctalia.kdl` include |
| Noctalia bar blur/transparency | Noctalia `transparency_mode` + Niri `background-effect`/`blur` |
| Application theme adapters | `shell-conf` / `sync-livara-themes` |

## Noctalia visual contract

The integration installs stable intent through `shell-conf/config/noctalia/config.toml`. The runtime package comes from `noctalia-conf`; template source and plugin source are immutable store inputs; generated outputs live under `$XDG_STATE_HOME/livara/theme` and application profiles. The central flow is:

> Local wallpaper in `~/Wallpapers` → Noctalia v5 palette/templates (`m3-fruit-salad`) → `palette.dark.json` → Niri focus-ring include and application-specific adapters.

`shell-conf` owns native GTK, Qt, Firefox, Zen Browser, WezTerm, Kitty, Starship and KDE contracts. Local templates additionally generate the shared application palette, NixVim Lua colors, Firefox CSS, Zen Browser CSS and the Niri color include. The Niri template writes the regenerable `$XDG_CONFIG_HOME/niri/noctalia.kdl` file; the Home Manager-owned `config.kdl` includes it optionally and retains only compositor policy. `shell-conf` also materializes Freesm Launcher, Heroic, Foliate, Xournal++ and Vesktop contracts where the applications provide a documented customization path. The Livara Home Manager profile owns Nautilus, cmus and the Books/Games/Musics directory contract.

| Application/ecosystem | Generated output |
|---|---|
| Noctalia | `config.toml`, plugin source and user templates |
| GTK/Nautilus | Noctalia GTK templates plus stable icon settings; Nautilus owns native GTK/GVFS file browsing |
| Qt | Noctalia Qt/qtct templates |
| WezTerm/Kitty | Noctalia native template outputs |
| Neovim | `matugen_colors.lua` consumed by NixVim |
| Firefox/Zen Browser | Noctalia CSS outputs plus profile links |
| Nixvim Markdown | `vim-conf` Nixvim module, Treesitter grammars, renderer, Mermaid/LaTeX workflow and palette Lua |
| Freesm Launcher | Native application-specific theme |
| Vesktop | Local CSS and enabled theme selection |
| Xournal++ | GIMP `.gpl` palette + `colorPalette` |

Stylix compatibility is not claimed when an application lacks a Stylix contract. Stylix handles integrations it supports; Noctalia templates and documented adapters handle the rest. There is no Catppuccin source, and legacy tokens in an application format are not package dependencies.

## State and security

Evaluation builds closures and store references; realization occurs in Home Manager, systemd and session programs. Mutable data — palettes, browser profile CSS links, Vault checkouts, local wallpapers, plugin state and application profiles — remains outside the store. Activation does no downloads or `git pull`; timers and independent services synchronize after the session is available.

The Vault sync service performs a fast-forward-only pull on its timer and the session-stop service attempts a guarded Markdown commit/push. Sudden power loss, forced reset or kernel panic cannot execute an `ExecStop`, so those cases are not guaranteed by systemd. The active workflow has no editor-specific plugin asset materializer; the Vault remains the owner of plain Markdown, while Nixvim owns editor behavior and Xournal++ owns `.xopp` documents.

## Isolation and AppImages

Firejail is retained only as an application security boundary. The shared feature owns its profiles and wrappers once through `commonDesktop`; host modules must not import it again. The AppImage launcher composes the NixOS `appimage-run` FHS/bwrap compatibility layer inside Firejail with `--net=none`, `--caps.drop=all` and no implicit profile, while accepting only the file explicitly selected by the user. Firejail's native AppImage path is not used because generic AppImages need the NixOS FHS compatibility runner, and seccomp is not added to this composition because it can interfere with the inner namespace setup.

`nix-shell`/`nix develop` is not a security sandbox: it supplies reproducible development dependencies and environment variables. It therefore cannot replace Firejail for Brave, Vesktop, Telegram, MPV or arbitrary AppImages. The installer uses `nix develop --no-update-lock-file` only to make the rebuild toolchain reproducible; application isolation remains a separate runtime concern.

## Validation

Run the low-cost sequence first:

```bash
git diff --check
find src modules -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
nix flake check --no-build --no-update-lock-file --all-systems
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
niri validate --config ~/.config/niri/config.kdl
```

Then evaluate or build each affected host on a machine with sufficient Nix store capacity:

```bash
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
nix build .#nixosConfigurations.latitude.config.system.build.toplevel
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
```

On the real host, run `noctalia msg plugins list`, the generated palette/application checks, `keyd check`, and hardware/audio/portal checks. A constrained sandbox can establish syntax and graph consistency but cannot prove visual behavior, GPU capture, monitor discovery or lock/suspend behavior on physical hardware.

## References

[1]: https://mhwombat.codeberg.page/nix-book/ "Mhwombat Nix Book"
[2]: https://edolstra.github.io/pubs/phd-thesis.pdf "The Purely Functional Software Deployment Model"
[3]: https://ekala-project.github.io/nix-book/ "Ekala Nix Book"
[4]: https://saylesss88.github.io/ "Saylesss88 Nix Book"
[5]: https://wiki.nixos.org/wiki/Niri "NixOS Wiki — Niri"
[6]: https://docs.noctalia.dev/noctalia/ "Noctalia v5 documentation"
[7]: https://github.com/noctalia-dev/official-plugins "Noctalia official plugins"
[8]: https://github.com/rvaiya/keyd "keyd"
