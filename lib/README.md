# `lib`

The builder layer — turns `hosts/<name>/default.nix` and
`homes/<user>/machines/<name>.nix` into real flake outputs
(`nixosConfigurations`, `darwinConfigurations`, `homeConfigurations`). If
`modules/README.md` documents *what a host is made of*, this is *how a host
(or a standalone machine) actually gets built*.

```
lib/
├── hostSchema.nix        typed schema for a real host's `host` data
├── mkConfigurations.nix  the three builders (see below)
└── nixpkgsConfig.nix     shared nixpkgs config/overlays, used by both
```

## `hostSchema.nix`: real types instead of hand-rolled asserts

Every `hosts/<name>/default.nix` returns `{ host; module; }` — `host` is
plain data (name, system, channel, and the `hardware`/`environment`/`tools`
groups documented in `modules/README.md`). `lib/mkConfigurations.nix`
validates that data through this schema via `lib.evalModules`, *before* any
real NixOS/darwin module evaluation starts — enums catch typos as normal Nix
type errors, and the derived fields (`isLinux`, `isServer`, etc.) get
computed once here rather than by each consumer. This same schema is reused
as a real `config.host` option inside the module tree too (see
`modules/host/default.nix`) — one declaration, no drift between the
pre-fixpoint check and the real option.

## `mkConfigurations.nix`: three builders from two kinds of source files

- **`nixosConfigurations`/`darwinConfigurations`** — one per `hosts/<name>/`
  directory (auto-detected, no hardcoded list). Picks `nixosSystem` or
  `darwinSystem` by `host.isLinux`/`isDarwin`, picks the nixpkgs/home-manager
  channel by `host.channel`, injects `modules/host` plus the agenix/disko/
  home-manager flake modules per `host.tools.*`, and hands `host` to every
  injected module as a specialArg.
- **`homeConfigurations`** — one per `homes/<user>/machines/<name>.nix` file
  (same auto-detection style). Builds a `pkgs` directly (not through the
  NixOS/darwin module system) and calls
  `home-manager.lib.homeManagerConfiguration` with `homes/default.nix` +
  `homes/<user>/` as modules — the exact same home content a real host's
  `home-manager.users.<user>` gets, reused unchanged. No `host` specialArg is
  available to this content (there's no host at all), which is why
  `homes/default.nix` and everything under `homes/<user>/` only ever take
  `pkgs`/`lib`/`inputs` as arguments, never `host`.

Both paths funnel through the same channel-selection tables
(`channelInputs`, `homeManagerInputs`) so "which nixpkgs/home-manager release"
is answered identically regardless of which builder is running.

## `nixpkgsConfig.nix`: why a real host and a standalone machine need the same overlays

`homes/` content is shared verbatim between real hosts and standalone
machines — e.g. `homes/dami/dev/rust`'s `pkgs.stable.cargo-watch` (a pin
around an unstable-channel darwin linker crash) needs `pkgs.stable` to exist
*regardless* of which of the two ways `pkgs` was constructed. This file is
the single source for `allowUnfree`/`permittedInsecurePackages` and the
overlays (`mylib`, the `pkgs.stable`/`unstable`/`master` multi-channel set) —
`modules/host/nix/default.nix` uses it to set the real
`nixpkgs.config`/`nixpkgs.overlays` options for a NixOS/darwin host, and
`mkConfigurations.nix`'s standalone builder uses it to construct `pkgs`
directly via `import`. Add an overlay or config key once, here, not twice.

## Adding a new host or standalone machine

- **Real host** (NixOS or darwin): `hosts/<name>/default.nix` returning
  `{ host; module; }` — see any existing host file for the shape, and
  `modules/README.md` for what `host.*` fields are available.
- **Standalone machine**: `homes/<user>/machines/<name>.nix` — see
  `homes/README.md`.

Neither needs an edit anywhere else in the repo; both are picked up by
`readDir`-based auto-detection.
