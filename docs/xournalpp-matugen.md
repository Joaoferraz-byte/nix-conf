# Xournal++ configuration flow

`xournal-conf` is the versioned data repository consumed by `nix-conf`. The native Xournal++ profile used by this configuration is `$XDG_CONFIG_HOME/xournalpp`, normally `~/.config/xournalpp`. The path `~/.config/com.github.xournalpp.xournalpp` is not part of the native profile contract and must not be used as a second source of truth unless a separately installed package explicitly requires it.

## Ownership and paths

| Layer | Path | Owner | Purpose |
| --- | --- | --- | --- |
| Versioned source | `~/Projects/xournal-conf/xournalpp/` | `xournal-conf` | Reviewed settings, toolbar, palette and LaTeX template |
| Editable staging | `~/.config/nixos/xournalpp/` | Home Manager activation | Writable copy used by the Xournal++ UI |
| Live application path | `~/.config/xournalpp/` | Xournal++ | Out-of-store symlinks to the editable staging files |
| Dynamic desktop theme | `~/.config/gtk-3.0/dank-colors.css` | DMS/Matugen | GTK appearance consumed by GTK applications, including Xournal++ |

The application settings and toolbar are intentionally seeded only when the editable staging files do not exist. This allows the Xournal++ interface to modify them without every activation overwriting the user’s work. The palette, LaTeX template and other immutable assets remain linked from the flake input.

## Editing and publishing

Close Xournal++ before synchronizing. To publish the current UI configuration into the repository, run:

```bash
/home/livara/Projects/nix-conf/scripts/sync-xournalpp-config.sh --push /home/livara/Projects/xournal-conf
```

Review the diff, then commit and push from the `xournal-conf` checkout. To pull a reviewed repository change into the active profile, run:

```bash
/home/livara/Projects/nix-conf/scripts/sync-xournalpp-config.sh --pull /home/livara/Projects/xournal-conf
```

Restart Xournal++ after a pull. If the user copies from `~/.config/xournalpp` directly, the path may be an out-of-store symlink; the canonical editable files are under `~/.config/nixos/xournalpp/`. Copying from the wrong path can therefore preserve stale content or overwrite the wrong repository.

## Current profile decisions

The versioned profile forces dark mode, uses a black page background, assigns Tokyo Night gold (`#e0af68`) to the highlighter, sets the eraser to `VERY_FINE`, and places `HIGHLIGHTER` followed by `ERASER` at the beginning of the custom tool cluster. The duplicate adjacent separators were removed from `toolbar.ini`.

DMS/Matugen owns the desktop GTK palette. Xournal++ owns its semantic drawing configuration. This is deliberate: a direct Matugen template that rewrites the complete `settings.xml` would compete with UI edits and make the application profile non-deterministic. Xournal++ should consume the DMS-generated GTK appearance while keeping tool behavior and page semantics in `xournal-conf`.

## References

1. [Xournal++ file locations](https://xournalpp.github.io/guide/file-locations/)
2. [Xournal++ toolbar colors](https://xournalpp.github.io/guide/config/toolbar-colors/)
3. [Xournal++ eraser](https://xournalpp.github.io/guide/tools/eraser/)
4. [DankMaterialShell application themes](https://danklinux.com/docs/dankmaterialshell/application-themes)
