# Per-user home-manager wiring. Only imported when host.tools.homeManager.enable
# is true (see modules/host/default.nix's imports) — the `home-manager`
# option itself only exists once lib/mkConfigurations.nix injects the
# flake-input home-manager module (whichever channel — see
# host.tools.homeManager.channel and modules/README.md), so this file can't
# be imported unconditionally the way most modules/host/<topic> files are.
#
# homes/default.nix carries the recommended baseline (fontconfig, xdg,
# programs.man/home-manager) and is auto-imported for every user here —
# a user's own homes/<username>/ only needs its tool-specific modules, not a
# copy of the baseline.
{
  lib,
  inputs,
  host,
  ...
}:
{
  config.home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = lib.mkForce "old";
    extraSpecialArgs = { inherit inputs; };

    users.${host.environment.user.username} = {
      imports = [
        (inputs.self + "/homes/default.nix")
      ]
      ++ lib.optional (builtins.pathExists (inputs.self + "/homes/${host.environment.user.username}")) (
        inputs.self + "/homes/${host.environment.user.username}"
      );

      home.stateVersion = host.stateVersion; # this we keep as fall back
    };
  };
}
