{ pkgs, ... }:
{
  imports = [
    ./boot.nix
    ./disko.nix
    ./fonts.nix
    ./intel.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./power.nix
    ./security.nix
    ./user.nix
  ];

  environment.systemPackages = with pkgs; [
    bottom
    gitMinimal
  ];

  system.stateVersion = "25.11";
}
