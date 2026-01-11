{ pkgs, inputs, ... }:
{
  imports = [
    ./system
  ];

  environment.systemPackages = [
    inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];

  system = {
    primaryUser = "dami";
    nixpkgsRelease = "25.11";
    stateVersion = 6;
  };
}
