{
  lib,
  host,
  inputs,
  ...
}:
let
  # lib/nixpkgsConfig.nix — shared with lib/mkConfigurations.nix's standalone
  # home-manager builder, which constructs its own `pkgs` outside this module
  # system but needs the same overlays (homes/ content like
  # homes/dami/dev/rust's `pkgs.stable.cargo-watch` is shared by both paths
  # and breaks if either one's overlays drift out of sync).
  shared = import ../../../lib/nixpkgsConfig.nix {
    inherit inputs;
    inherit (host) system;
  };
in
{
  config = {
    nixpkgs = {
      inherit (shared) config overlays;
    };

    nix = {
      optimise.automatic = true;

      gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      }
      // (
        if host.isLinux then
          { dates = "weekly"; }
        else
          {
            interval = {
              Weekday = 0;
              Hour = 3;
              Minute = 0;
            };
          }
      );

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];

        connect-timeout = 5;
        max-jobs = "auto";
        sandbox = true;

        keep-outputs = true;
        keep-derivations = true;

        use-xdg-base-directories = true;

        download-buffer-size = 2147483648;

        trusted-users = [
          "root"
          (if host.isLinux then "@wheel" else "@admin")
        ];
        allowed-users = [ (if host.isLinux then "@users" else "@admin") ];
      };
    };

    environment.shellAliases = {
      clean = "sudo -H nix-collect-garbage -d && nix-collect-garbage -d";
      rebuild =
        if host.isLinux then
          "sudo -H nixos-rebuild switch --flake"
        else
          "sudo darwin-rebuild switch --flake";
    };
  }
  // lib.optionalAttrs host.isLinux {
    documentation.nixos.enable = false;
  };
}
