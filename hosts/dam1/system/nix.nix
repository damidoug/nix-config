{ lib, pkgs, ... }:
{
  nix = with lib; {
    package = mkDefault pkgs.lix;

    optimise.automatic = true;

    # Avoid build-user exhaustion on bigger builds
    nrBuildUsers = 32;

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };

    settings = {
      experimental-features = mkDefault [
        "nix-command"
        "flakes"
      ];

      allowed-users = mkDefault [
        "root"
        "dami"
      ];
      trusted-users = mkDefault [
        "root"
        "dami"
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
      max-jobs = 4;
      sandbox = true;
      use-xdg-base-directories = true;

      keep-outputs = true;
      keep-derivations = true;
    };

    linux-builder = {
      enable = true;

      # Keep store between reboots (MUCH faster builds)
      ephemeral = false;

      # Relative speed vs other builders
      speedFactor = 2;

      # Linux systems you may want to build
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      # Fine-tune the Linux VM itself
      config.virtualisation = {
        cores = 4; # M1 Air = 8 cores total, 4 is safe
        memorySize = mkForce 4096; # 4 GB RAM for the VM
      };
    };
  };
}
