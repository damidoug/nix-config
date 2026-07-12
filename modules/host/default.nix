# Aggregator + option bridge for the modules/host/<topic> tree.
#
# `host` (the specialArg — plain data, validated pre-fixpoint by
# lib/hostSchema.nix) is mirrored into a real `config.host` option here,
# reusing lib/hostSchema.nix as the submodule type so the two never drift
# apart. Topic modules below read typed values off `config.host.*`; the raw
# `host` specialArg still exists too, for leaf configs (hosts/pc/gaming,
# hosts/pc/services) that just want plain data without the module system.
#
# `system.stateVersion` is set here automatically from host.isLinux/isDarwin
# — NixOS wants host.stateVersion (a "26.05"-style string) directly; darwin
# wants its own separate small integer (host.darwinStateVersion, tracked
# independently by nix-darwin, not derivable from the nixpkgs release
# string). No host hand-sets stateVersion in its own `module` block.
{
  lib,
  host,
  ...
}:
{
  options.host = lib.mkOption {
    type = lib.types.submodule (import ../../lib/hostSchema.nix);
    description = "Per-host data — see lib/hostSchema.nix for the full schema.";
  };

  imports = [
    # cross-platform — branches internally on host.isLinux/isDarwin
    ./nix/default.nix
  ]
  ++ lib.optionals host.isLinux [
    ./audio/nixos.nix
    ./bluetooth/nixos.nix
    ./boot/nixos.nix
    ./cpu/nixos.nix
    ./disk/nixos.nix
    ./gnome/nixos.nix
    ./gpu/nixos.nix
    ./locale/nixos.nix
    ./networking/nixos.nix
    ./openssh/nixos.nix
    ./power/nixos.nix
    ./user/nixos.nix
  ]
  ++ lib.optionals host.isDarwin [
    ./locale/darwin.nix
    ./networking/darwin.nix
    ./openssh/darwin.nix
    ./power/darwin.nix
    ./user/darwin.nix
  ]
  # gated on the `host` specialArg, not `config.host.tools.homeManager.enable`
  # — the `home-manager` option itself only exists once the flake-input
  # module is injected for that setting (see lib/mkConfigurations.nix), so
  # this needs to be a conditional import, not an always-imported file with
  # an internal `mkIf`/`optionalAttrs`. See modules/README.md's two
  # conditional-evaluation traps for why that distinction matters.
  ++ lib.optional host.tools.homeManager.enable ./home-manager;

  config = {
    # `host` (the specialArg) already carries the derived, readOnly fields
    # (arch/os/isLinux/isDarwin/isDesktop/isLaptop/isServer/isWorkstation/
    # isQemu) computed by lib/hostSchema.nix's pre-fixpoint pass. Since
    # `config.host` reuses that same schema as its submodule type, it would
    # independently re-derive those same fields from `system`/`type` —
    # passing the already-derived values back in as a second definition trips
    # NixOS's "readOnly option defined multiple times" check. Strip them so
    # only the raw fields are assigned and the submodule derives the rest
    # itself (same pure computation, same result, just not double-defined).
    host = removeAttrs host [
      "arch"
      "os"
      "isLinux"
      "isDarwin"
      "isDesktop"
      "isLaptop"
      "isServer"
      "isWorkstation"
      "isQemu"
    ];

    system.stateVersion = if host.isLinux then host.stateVersion else host.darwinStateVersion;
  };
}
