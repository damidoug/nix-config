# `homes/dami/shell`

Interactive shell environment for `damidoug` — one directory per tool, wired
into `homes/dami/default.nix` via `imports = [ ./apps ./dev ./shell ];`.

```
shell/
├── default.nix   imports every module below
├── core/         loose CLI utils with no config of their own
├── fish/         fish — the shell itself
├── bat/          bat        (cat replacement)
├── eza/          eza        (ls replacement)
├── fd/           fd         (find replacement)
├── fzf/          fzf        (fuzzy finder)
├── zoxide/       zoxide     (cd replacement)
├── helix/        helix      (terminal editor, $EDITOR)
├── ghostty/      ghostty    (terminal, $TERMINAL)
├── fastfetch/    fastfetch  (system info)
└── starship/     starship   (prompt) + nerd fonts + starship.toml
```

## How a module is put together

Every subdirectory owns everything about its tool — not just the package, but
the alias that invokes it, the env var it sets, its shell integration, and the
rule that tells Claude Code how to use it. home-manager merges all of these
across modules, so nothing needs a central file:

| Piece | Option | Merged how |
| --- | --- | --- |
| Package / settings | `home.packages`, `programs.<tool>` | — |
| Alias | `home.shellAliases.<name>` | attrs union |
| Env var | `home.sessionVariables.<NAME>` | attrs union |
| Shell integration | `programs.fish.{shellInit,interactiveShellInit}` | lines concat |
| Claude rule | `programs.claude-code.rules.<name>` | attrs union |

That's why, for example, `cat = "bat …"` lives in `bat/` and `cd = "z"` lives
in `zoxide/` rather than in one shared alias block — each alias sits next to
the tool it points at, and adding a tool never means editing an unrelated
file.

## Module reference

| Module | Package / `programs.*` | Alias(es) | Env var | Rule key |
| --- | --- | --- | --- | --- |
| **`core/`** | curl, wget, rsync, ffmpeg, jq, yq, desktop-file-utils, git + (Linux only) xclip, pciutils, usbutils | — | — | — |
| **`fish/`** | `fish` | — | — | `shell` |
| **`bat/`** | `bat` (+ fish batman/batpipe) | `cat` | — | `cat` |
| **`eza/`** | `eza` | `ls`, `ll`, `la`, `lt` | — | `ls` |
| **`fd/`** | `fd` | — | — | `finder` |
| **`fzf/`** | `fzf` | — | — | `fzf` |
| **`zoxide/`** | `zoxide` | `cd` | — | `cd` |
| **`helix/`** | `helix` (base: theme, cursor-shape only) | `vi`, `vim`, `nano` | `EDITOR=hx` | `cli editor` |
| **`ghostty/`** | `ghostty` | — | `TERMINAL=ghostty` | `terminal` |
| **`fastfetch/`** | `fastfetch` | — | — | `fastfetch` |
| **`starship/`** | `starship` + nerd fonts | — | — | `starship` |

> `git` in `core/` is the plain git binary, kept only for tool compatibility —
> the actual VCS is jujutsu (`jj`), configured in `dev/vcs/`.

> `xclip`, `pciutils`, and `usbutils` in `core/` are gated behind
> `lib.optionals pkgs.stdenv.isLinux` — they rely on X11 / PCI / USB bus
> enumeration that doesn't exist on macOS (which has built-in `pbcopy`/`pbpaste`
> instead of `xclip`, and no `lspci`/`lsusb` equivalent). Same pattern as
> `programs.aerospace.enable = pkgs.stdenv.isDarwin` in `apps/aerospace/`, just
> mirrored for the Linux-only direction.

> `helix/` only carries the base editor (theme, cursor-shape) — same split as
> `dev/zed/`. Per-language LSP/formatter config for Helix lives in the
> matching `dev/<tool>` module (`programs.helix.languages.*`), documented in
> `homes/dami/dev/README.md`. `hx --health <language>` shows what's actually
> wired for any given language.

## Starship prompt

`starship/starship.toml` is the single settings source (`programs.starship.settings`
imports it via `lib.importTOML`); `starship/default.nix` only wires it up and
installs the nerd fonts (FiraCode, DroidSansMono, MesloLG).

- **Icons** are the upstream **Nerd Font Symbols** preset (~60 languages).
  It's kept whole here rather than fragmented into the `dev/<tool>` folders —
  it's one cohesive cosmetic block, and most of its symbols are for languages
  with no dev-tool folder.
- **`command_timeout = 1300`** (root key at the top of the file): raised from
  the 500 ms default because `git status` over the nix store or a large repo
  routinely exceeds it and prints "command timed out".
- **`[custom.jj]`**: since the VCS is jujutsu and starship has no native jj
  module, this shows the current change (short id · bookmarks · description)
  when inside a jj repo. It runs `jj … --ignore-working-copy` so rendering the
  prompt never snapshots the repo. The built-in `git_*` modules stay enabled;
  they only render when a `.git` exists, so non-colocated jj repos show just
  the jj module.

## Adding a new tool

1. Create a directory with a `default.nix` (`{ pkgs, ... }: { ... }`).
2. Add the package (`home.packages`) or enable its `programs.<tool>` module.
3. Co-locate everything else here, not in a shared file: its alias
   (`home.shellAliases.<name>`), any env var (`home.sessionVariables`), and
   any shell integration (`programs.fish.interactiveShellInit`).
4. Write `programs.claude-code.rules.<name>` describing how to use it: the
   command, what it replaces ("`cat` = bat", "NOT find"), and any aliasing so
   Claude doesn't reach for the wrong tool.
5. Add the directory to the `imports` list in `homes/dami/shell/default.nix`.
