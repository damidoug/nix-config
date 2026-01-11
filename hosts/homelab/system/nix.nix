{ lib, pkgs, ... }:
{
  nix = with lib; {
    package = mkDefault pkgs.lix;

    optimise.automatic = true;

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };

    settings = {
      experimental-features = mkForce [
        "nix-command"
        "flakes"
      ];

      allowed-users = mkDefault [
        "root"
        "homelab"
      ];
      trusted-users = mkDefault [
        "root"
        "homelab"
      ];

      trusted-public-keys = mkForce [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      substituters = mkForce [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];

      connect-timeout = 5;
      max-jobs = "auto";
      sandbox = true;
      use-xdg-base-directories = true;

      keep-outputs = true;
      keep-derivations = true;
    };
  };

  nixpkgs.config.allowUnfree = true;
}
