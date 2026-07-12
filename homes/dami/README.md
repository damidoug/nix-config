# `homes/dami`

home-manager configuration for the user `damidoug`. This is the whole
user-level environment — GUI apps, dev toolchain, shell — as opposed to
`hosts/`, which configures the system (NixOS/nix-darwin) each of these runs
on.

```
homes/dami/
├── default.nix   base/root module: imports + foundational settings only
├── README.md     this file
├── apps/         GUI applications              → apps/README.md
├── dev/          development toolchain          → dev/README.md
└── shell/        interactive shell environment  → shell/README.md
```

## Wiring

```
lib/mkConfigurations.nix
  → modules/host/home-manager/default.nix   (only when host.tools.homeManager.enable)
      home-manager.users.${host.environment.user.username}.imports = [
        homes/default.nix        # recommended baseline, every home-manager profile
        homes/dami/               # this directory, if it exists
      ]
      extraSpecialArgs = { inherit inputs; }
    → homes/dami/default.nix
        imports = [ ./apps ./dev ./shell ]
```

The same `homes/dami/` content is also reused, unchanged, by standalone
(non-NixOS/darwin) home-manager machines — see `lib/README.md` and
`homes/README.md` for that mechanism.

Every module under `apps/`, `dev/`, and `shell/` receives `pkgs`, `lib`,
`config`, and `inputs` as available function arguments (via
`extraSpecialArgs`) — destructure only what you actually use. `host` is
*not* available here — it's a real host's specialArg only, and this content
is shared with standalone machines that have no `host` at all.

## `default.nix`: imports only, nothing else

`homes/dami/default.nix` is just `imports = [ ./apps ./dev ./shell ];` —
genuinely nothing else. Foundational settings that apply to *any* home
(`fonts.fontconfig`, `xdg.enable`, `programs.man`,
`programs.home-manager.enable`) live one level up in `homes/default.nix`
instead, since they're not specific to this one user and are shared with
standalone machines too — see `homes/README.md`.

## The three areas

| Area | What it covers | README |
| --- | --- | --- |
| **`apps/`** | GUI applications — window manager, browser, Discord client, password manager | [apps/README.md](apps/README.md) |
| **`dev/`** | Languages, CLI dev tools, both editors' (Zed + Helix) per-tool LSP/formatter config | [dev/README.md](dev/README.md) |
| **`shell/`** | The interactive shell itself — fish, prompt, and everyday CLI replacements (bat, eza, fd, fzf, zoxide) | [shell/README.md](shell/README.md) |

Each has its own README with a full module reference table; this file only
covers what's shared across all three.

## Shared philosophy

All three areas follow the same rules, worked out and refined across several
reorganizations of this tree:

1. **One directory per concern, each a `default.nix`, aggregated by a
   literal `imports` list.** No auto-discovery, no `readDir` magic — every
   module is named explicitly in its parent's `imports`.

2. **A module owns everything about its tool** — not just the package, but
   its aliases, env vars, editor LSP config, and its
   `programs.claude-code.rules.<name>` entry. home-manager merges these
   (lists concatenate, attrsets union) across every module that sets them,
   verified with real evals rather than assumed, so nothing needs a central
   file.

3. **Cross-cutting config lives with what it configures, not with what it's
   "about."** The clearest example: aerospace keybindings and Brave
   extensions are options owned by `apps/aerospace/` and `apps/brave/`
   respectively, but each individual binding/extension is set in the module
   of the app it launches or extends — e.g. the Zed launch keybinding
   (`alt-c`) is set in `dev/zed/`, not `apps/aerospace/`. See
   [apps/README.md](apps/README.md#cross-cutting-config-bindings-and-extensions-live-with-what-they-launch).

4. **Single source of truth for values that matter in two places.** E.g.
   ruff's line-length is declared once in `dev/python/` and reused for both
   `programs.ruff.settings.line-length` and Zed's `preferred_line_length` —
   never hand-duplicated. See
   [dev/README.md](dev/README.md#single-source-of-truth-for-shared-settings).

5. **Only configure what isn't already the default.** Before adding editor
   config for a language, check what Helix/Zed already do out of the box
   (`hx --health <language>` for Helix) — most well-known LSPs are already
   wired upstream. See
   [dev/README.md](dev/README.md#helix-only-add-whats-not-already-default).

6. **Claude rules are documentation that ships with the config, not
   separate from it.** Every `programs.claude-code.rules.<name>` merges into
   `~/.claude/rules/*.md` at build time — Claude reads the same facts a
   human would find in these READMEs, generated from the same source.

## Adding something new

Not sure which area it belongs in?

- Has a `.app` bundle / GUI window → `apps/`
- Is invoked from the terminal for programming (a language, CLI tool,
  linter, either editor's LSP config) → `dev/`
- Is part of the shell environment itself (a `programs.*` module that
  changes how the terminal behaves, an alias, the prompt) → `shell/`

Then follow that area's own "Adding a new X" section — the exact steps
differ slightly (Zed/Helix wiring in `dev/`, aliases/env vars in `shell/`,
aerospace bindings/Brave extensions in `apps/`) but the shape is the same:
new directory, own `default.nix`, own rule if there's something worth
telling Claude, added to the parent's `imports`.

## Verifying changes

None of this needs a full rebuild to check. From the repo root:

```sh
nix flake check --no-build   # evaluates the whole tree
nix eval .#darwinConfigurations.mac.config.home-manager.users.dami.<path> --json
```

The second form is fast (evaluation only, no build) and is how every merge
claim in these READMEs was actually verified — point it at any option path
to see the fully-merged result across every module that contributes to it.
