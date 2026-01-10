{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  disabledModules = [ "programs/aerospace.nix" ];

  imports = [ "${inputs.home-manager-unstable}/modules/programs/aerospace.nix" ];

  programs.aerospace = {
    enable = pkgs.stdenv.isDarwin;
    launchd.enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.aerospace;
    settings = lib.importTOML ./aerospace.toml;
  };
}
