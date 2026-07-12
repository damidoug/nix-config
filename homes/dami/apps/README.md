# `homes/dami/apps`

GUI applications for `damidoug` — one directory per app, wired into
`homes/dami/default.nix` via `imports = [ ./apps ./dev ./shell ];`.

```
apps/
├── default.nix   imports every module below
├── aerospace/    tiling window manager (macOS only) + workspace/focus keybindings
├── bitwarden/    password manager + its Brave extension + aerospace binding
├── brave/        browser core config + locale + ownerless extensions
└── vesktop/      Discord client + Vencord plugins/theme + its Brave extension
```

Same convention as `dev/` and `shell/`: each module owns its package(s),
`programs.*` config, and — where genuinely useful for Claude to know — a
co-located `programs.claude-code.rules.<name>`. Not every app has a rule;
GUI apps with no coding-relevant behavior don't get one just to fill the
slot.

## Cross-cutting config: bindings and extensions live with what they launch

Two options are shared across every app but aren't owned by any single
module: `programs.aerospace.settings.mode.main.binding` (a nested attrset)
and `programs.brave.extensions` (a list). Both merge cleanly across every
module that sets them — verified with a real `lib.evalModules` eval, not
assumed — so **each app-launch keybinding and each Brave extension lives in
the module of the app it launches/extends**, not centralized in
`aerospace/` or `brave/`:

| Binding / extension | Lives in |
| --- | --- |
| `alt-enter` → open $TERMINAL | `shell/ghostty/default.nix` |
| `alt-f` → open Finder | `apps/aerospace/` (Finder has no module of its own) |
| `alt-b` → open Brave | `apps/brave/default.nix` |
| `alt-c` → open Zed | `dev/zed/default.nix` |
| `alt-p` → open Bitwarden | `apps/bitwarden/default.nix` |
| dark reader (Brave ext) | `apps/brave/default.nix` (no other owner) |
| vencord web (Brave ext) | `apps/vesktop/default.nix` (mirrors the desktop Vencord config) |
| bitwarden (Brave ext) | `apps/bitwarden/default.nix` |

`apps/aerospace/` itself only keeps the workspace/focus/move/service-mode
bindings — the ones that aren't tied to launching a specific app — plus
`alt-f`, which has nowhere else to live.

## Module reference

| Module | Package / `programs.*` | Also contributes | Rule key |
| --- | --- | --- | --- |
| **`aerospace/`** | `aerospace` (macOS-only, `pkgs.stdenv.isDarwin`) | — | `aerospace` |
| **`bitwarden/`** | `bitwarden-desktop` | `brave.extensions` (bitwarden), `aerospace` binding (alt-p) | `bitwarden` |
| **`brave/`** | `brave` | `aerospace` binding (alt-b) | `brave` |
| **`vesktop/`** | `vesktop` (Discord + Vencord) | `brave.extensions` (vencord web) | `vesktop` |

## Adding a new app

1. Create a directory with a `default.nix` (`{ pkgs, ... }: { ... }`).
2. Add the package (`home.packages`) or enable its `programs.<app>` module.
3. If it launches via an aerospace keybinding, set that binding here:
   `programs.aerospace.settings.mode.main.binding.alt-X = "exec-and-forget open -a '<App>'";`
   — not in `apps/aerospace/`.
4. If it has a Brave extension, add its ID here:
   `programs.brave.extensions = [ "<extension-id>" ];` — not in
   `apps/brave/`.
5. Write `programs.claude-code.rules.<name>` if there's something Claude
   would actually need to know (a keybinding it should reference, a default
   it shouldn't assume, "NOT X" guidance) — skip it otherwise.
6. Add the directory to the `imports` list in `homes/dami/apps/default.nix`.
