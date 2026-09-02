# Xournal++ configuration flow

`xournal-conf` is the versioned data repository consumed by `nix-conf`. The native Xournal++ profile used by this configuration is `$XDG_CONFIG_HOME/xournalpp`, normally `~/.config/xournalpp`. The path `~/.config/com.github.xournalpp.xournalpp` is not part of the native profile contract and must not be used as a second source of truth unless a separately installed package explicitly requires it.

## Ownership and paths

| Layer | Path | Owner | Purpose |
| --- | --- | --- | --- |
| Versioned source | `~/Projects/xournal-conf/xournalpp/` | `xournal-conf` | Reviewed settings, toolbar, palette and LaTeX template |
| Native editable profile | `~/.config/xournalpp/` | Home Manager activation + Xournal++ | Writable source consumed directly by Xournal++ |
| Legacy migration source | `~/.config/nixos/xournalpp/` | One-time activation migration | Read only when the native file does not exist |
| Dynamic desktop theme | `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` | Noctalia | GTK appearance consumed by GTK applications, including Xournal++ |

The application settings and toolbar are intentionally seeded only when the native editable files do not exist. This allows the Xournal++ interface to modify them without every activation overwriting the user’s work. The requested `defaultSaveName=%F` convention is a narrow declarative policy: activation converges that one property in an existing profile, while other UI-editable settings remain untouched. The static Tokyo Night palette remains available from the flake input, while the Noctalia runtime palette is generated dynamically from the active wallpaper. The runtime adapter updates only the `colorPalette` property in the editable owner, never the rest of `settings.xml`.

## Editing and publishing

Close Xournal++ before synchronizing. To publish the current UI configuration into the repository, run:

```bash
cd ~/.config/nixos
./scripts/sync-xournalpp-config.sh --push ~/Projects/xournal-conf
```

Review the diff, then commit and push from the `xournal-conf` checkout. To pull a reviewed repository change into the active profile, run:

```bash
cd ~/.config/nixos
./scripts/sync-xournalpp-config.sh --pull ~/Projects/xournal-conf
```

Restart Xournal++ after a pull. The canonical editable files are now under `~/.config/xournalpp/`, which is the native profile consumed by Xournal++. A previous `~/.config/nixos/xournalpp/` checkout is migrated only when the native file is absent; it is not an active second source of truth.

## Current profile decisions

The versioned profile forces dark mode, uses a black page background, assigns Tokyo Night gold (`#e0af68`) to the highlighter, sets the eraser to `VERY_FINE`, and places `HIGHLIGHTER` followed by `ERASER` at the beginning of the custom tool cluster. The duplicate adjacent separators were removed from `toolbar.ini`.

Noctalia owns the desktop GTK palette, while the Xournal++ adapter consumes its generated color values and writes the drawing-color palette. Xournal++ still owns its semantic drawing configuration. This is deliberate: rewriting the complete `settings.xml` would compete with UI edits and make the application profile non-deterministic. The adapter writes a valid GIMP `.gpl` file, keeps the first semantic role for each unique RGB value, and changes only `colorPalette` in `~/.config/xournalpp/settings.xml`; Home Manager converges the explicitly requested `defaultSaveName` property, and tool behavior, toolbar layout and page semantics remain under `xournal-conf`. The New Xournal helper creates native gzip-compressed Xournal++ XML and opens the resulting path, so the first Save targets that file instead of treating it as an unsaved document. When M3 roles coincide, later entries such as `Error` or `Primary Container` are omitted rather than duplicated, and Xournal++ handles the shorter palette according to its documented color-item behavior. The Noctalia configuration itself is not modified by this adapter.

## References

1. [Xournal++ file locations](https://xournalpp.github.io/guide/file-locations/)
2. [Xournal++ toolbar colors](https://xournalpp.github.io/guide/config/toolbar-colors/)
3. [Xournal++ eraser](https://xournalpp.github.io/guide/tools/eraser/)
4. [Noctalia documentation](https://docs.noctalia.dev/noctalia/)
