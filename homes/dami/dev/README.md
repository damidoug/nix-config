# `homes/dami/dev`

Development toolchain for `damidoug` — one directory per tool, wired into
`homes/dami/default.nix` via `imports = [ ./apps ./dev ./shell ];`.

```
dev/
├── default.nix   imports every module below
├── agenix/       age-encrypted secrets CLI
├── claude/       Claude Code itself (enable, settings, general plugins)
├── cloud/        flyctl, cloudflared
├── go/           go toolchain + gopls, gofumpt, delve, golangci-lint, air
├── js/           bun + biome
├── nix/          nixd, nixfmt, statix, deadnix, nix-tree, ...
├── proxy/        mitmproxy
├── python/       python314 + uv, ruff, ty
├── rust/         cargo, clippy, rustfmt, rust-analyzer, nextest, watch
├── sql/          sqlite, sqlx-cli, supabase-cli
├── vcs/          jujutsu (jj) + gh
└── zed/          zed-editor base config + ownerless extensions
```

## How a module is put together

Every subdirectory is self-contained: it owns everything about its tool, not
just the package.

| Piece | Option | Merged how |
| --- | --- | --- |
| Packages / settings | `home.packages`, `programs.<tool>` | — |
| Zed support | `programs.zed-editor.extensions`, `.userSettings` | list concat / deep attrs merge |
| Helix support | `programs.helix.languages.{language,language-server}` | list concat / attrs union |
| Claude plugin | `programs.claude-code.plugins` | list concat |
| Claude rule | `programs.claude-code.rules.<name>` | attrs union |

home-manager merges all five across every module that sets them, so nothing
lives in one giant central file — each piece of config sits next to the tool
it configures, and adding a tool never means editing an unrelated file.

## Module reference

| Module | Packages / `programs.*` | Zed | Helix | Claude plugin | Rule key |
| --- | --- | --- | --- | --- | --- |
| **`agenix/`** | `inputs.agenix.packages.<system>.default` | — | — | — | `agenix` |
| **`claude/`** | `claude-code` (enable, settings) | — | — | ponytail | `environment` |
| **`cloud/`** | flyctl, cloudflared | — | — | — | `cloudflared`, `flyctl` |
| **`go/`** | `go`, gopls, gofumpt, delve, golangci-lint, air, golangci-lint-langserver | ext + LSP | *(default upstream — package only)* | cc-skills-golang | `go` |
| **`js/`** | `bun`, biome | ext + LSP | `biome-lsp-proxy` (12 langs) | — | `js` |
| **`nix/`** | nixd, nixfmt, statix, deadnix, nixos-anywhere, nixos-rebuild, nix-tree | ext + LSP | formatter + nixd diagnostics | — | `nix` |
| **`proxy/`** | mitmproxy | — | — | — | `proxy` |
| **`python/`** | python314, `uv`, `ruff`, `ty` | LSP | auto-format + ty/ruff scoping | — | `python` |
| **`rust/`** | cargo, clippy, rustc, rustfmt, rust-analyzer, cargo-nextest, cargo-watch | LSP | rust-analyzer config | — | `rust` |
| **`sql/`** | sqlite, sqlx-cli, supabase-cli | ext | — | supabase/agent-skills | `sql` |
| **`vcs/`** | `gh`, `jujutsu` | ext | — | — | `vcs` |
| **`zed/`** | `zed-editor` base (enable, package, telemetry, format-on-save, wrap, nerd-font) | base + ownerless ext | — | — | `visual editor` |

(`shell/helix/` is Helix's equivalent base module — theme, cursor-shape.
Neither editor's base module carries language-specific config.)

> Supabase lives under `sql/`, not `cloud/` — it's a Postgres platform, so
> it's grouped with the other database tooling instead of the network/deploy
> tools.

> `nixos-rebuild` in `nix/` is deliberately *not* platform-gated: it's used
> from macOS to rebuild `pc`/`pangolin` remotely
> (`nixos-rebuild switch --target-host ...`), not just locally on a NixOS
> host. `darwin-rebuild` (macOS's own equivalent) is system-provided by
> nix-darwin, so it never needed a `home.packages` entry in the first place.

## Formatting at a glance

Every formatter-owning module tells Zed where to wrap, so the editor's guide
always matches what the formatter actually enforces:

| Language(s) | Formatter | Line length | Set in |
| --- | --- | --- | --- |
| Everything else (fallback) | — | 100 | `zed/` |
| Python | ruff | 100 | `python/` (`ruffLineLength`, shared with `programs.ruff`) |
| Rust | rustfmt | 100 *(rustfmt default, not overridden)* | `rust/` |
| JS/TS/JSX/TSX/JSON/CSS/HTML/GraphQL/Astro/Svelte/Vue | biome | 80 *(biome default, not overridden)* | `js/` (shared `biomeLanguage`) |
| Go | gofumpt | unbounded — gofmt intentionally has no line-length limit | `go/` (no override) |
| Nix | nixfmt | 100 *(nixfmt default — already matches the fallback)* | `nix/` (no override needed) |

## Adding a new tool

1. Create a directory with a `default.nix` (`{ pkgs, ... }: { ... }`).
2. Add packages to `home.packages` and/or enable the relevant `programs.*`
   module.
3. Give it Zed support here, not in `zed/default.nix`:
   `programs.zed-editor.extensions` for any extension it needs, and
   `programs.zed-editor.userSettings.{languages,lsp}.<name>` for its
   language server / formatter. If the formatter enforces a line width,
   set `preferred_line_length` to match it (see the table above).
3b. Give it Helix support here too, not in `shell/helix/default.nix` — but
   check what Helix already does by default first (see below) before adding
   anything.
4. If the tool ships a Claude Code plugin, add it to
   `programs.claude-code.plugins` here, not in `claude/`.
5. Write `programs.claude-code.rules.<name>` covering what Claude should
   never get wrong: exact commands (not close approximations), what NOT to
   use ("NOT git", "NOT pip"), and any setting that changes default tool
   behavior (line lengths, disabled telemetry, pinned versions).
6. Add the directory to the `imports` list in `homes/dami/dev/default.nix`.

## Single source of truth for shared settings

Some values are meaningful to more than one place — e.g. a formatter's line
length matters to both the formatter itself and to Zed's wrap guide. Rather
than duplicating the number, one module owns the real value and everything
else derives from it:

```nix
# python/default.nix
let
  ruffLineLength = 100;                       # <- the one true value
in {
  programs.ruff.settings.line-length = ruffLineLength;
  programs.zed-editor.userSettings.languages.Python.preferred_line_length =
    ruffLineLength;
}
```

The same pattern applies to Zed's ruff LSP, which only points at the `ruff`
binary and never re-declares its settings.

## Helix: only add what's not already default

Helix ships extremely comprehensive per-language defaults upstream (its own
bundled `languages.toml` already wires most well-known language servers by
name — `gopls`, `rust-analyzer`, `ty`, `ruff`, `nixd`, even `biome-lsp-proxy`
— the moment the binary exists on `$PATH`). Before adding Helix config to a
`dev/<tool>` module, check what's already covered
(`hx --health <language>` shows exactly what Helix resolved) rather than
re-declaring it. Concretely, across this repo:

| Module | What Helix already does by default | What we actually add |
| --- | --- | --- |
| `go/` | gopls + golangci-lint-lsp wired by name, auto-format on | nothing — just the missing `golangci-lint-langserver` binary |
| `rust/` | rust-analyzer wired, auto-format on | `checkOnSave`/`cargo`/`rustfmt` tuning (upstream sets none) |
| `python/` | ty + ruff both wired and both fully active | `auto-format = true` (upstream has no key = false) + scope ruff to format/code-action only, so it stops duplicating ty's diagnostics |
| `nix/` | nixd wired, `formatter = nixfmt` (bare, PATH-relying) | pin the formatter to the Nix store path; add nixd diagnostic suppression (upstream sets none) |
| `js/` | only `typescript-language-server` (not installed) | reference the upstream-known `biome-lsp-proxy` server + `auto-format = true` for the 12 biome-formatted languages |

A user-supplied `[[language]]` block partially overrides Helix's matching
built-in block by `name` — you only need to specify the fields you're
changing (e.g. `nix/` doesn't redeclare `file-types` or `indent` for nix,
just `auto-format` and `formatter`).

## Formatting & linting this repo

- Format: `nix fmt` (wired to `nixfmt` via the flake's `formatter` output),
  or on-save in Helix/Zed.
- Lint: `statix check .` (anti-patterns), `deadnix .` (dead code) — both
  installed by `nix/`.
