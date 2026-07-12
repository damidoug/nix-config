# Shared nixpkgs config + overlays — consumed both by modules/host/nix (sets
# the real config.nixpkgs.config/config.nixpkgs.overlays for every
# NixOS/darwin host) and by lib/mkConfigurations.nix's standalone
# home-manager builder, which constructs its own `pkgs` directly via `import
# nixpkgs {...}` outside the NixOS/darwin module system entirely. Takes
# `system` as an argument (not read off a `host` specialArg) so both call
# sites can supply it their own way.
{ inputs, system }:
let
  config = {
    allowUnfree = true;
    # electron-39.8.10 (EOL) is pulled in by vesktop (homes/dami/apps/vesktop) —
    # allow it explicitly rather than disabling the insecure-package check.
    permittedInsecurePackages = [ "electron-39.8.10" ];
  };
in
{
  inherit config;

  overlays = [
    # pkgs.mylib.* (e.g. homes/dami/dev/zed's darwin zed-editor build).
    inputs.mylib.overlays.default

    # Every-channel access without threading extra specialArgs around:
    # `pkgs.<pkg>` stays whichever channel this host is built on, while
    # `pkgs.stable`/`unstable`/`master` reach into the others — e.g.
    # `pkgs.stable.cargo-watch` (see homes/dami/dev/rust) when unstable's rust
    # toolchain fails to build a package, without switching the whole host's
    # channel. Built with `import ... { config = ...; }` rather than bare
    # `.legacyPackages.${system}`, which has default config (no
    # allowUnfree/permittedInsecurePackages) and would fail on packages the
    # "main" pkgs already allows. `homes/` content is shared by both
    # NixOS/darwin hosts and standalone machines, which is why this lives
    # here instead of inline in modules/host/nix.
    (_final: _prev: {
      stable = import inputs.nixpkgs-stable { inherit system config; };
      unstable = import inputs.nixpkgs { inherit system config; };
      master = import inputs.nixpkgs-master { inherit system config; };
    })
  ];
}
