# flake.nix
{
  description = "Douglas Damiano's Minimalist Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-master.url = "github:nixos/nixpkgs";

    # master branch — pairs with nixpkgs (unstable) and nixpkgs-master alike;
    # used for any host.channel != "stable" (see lib/mkConfigurations.nix).
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # release-26.05 branch — required pairing for host.channel == "stable"
    # (nixpkgs-stable is nixos-26.05), recommended but not strictly required
    # by home-manager itself — see modules/README.md's `homeManager` section.
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # master branch — pairs with nixpkgs (unstable) and nixpkgs-master alike;
    # used for any host.channel != "stable".
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin-26.05 branch — REQUIRED pairing for host.channel == "stable"
    # (unlike home-manager, nix-darwin's stable branch isn't just recommended
    # — the unstable/master branch isn't guaranteed to work against
    # nixpkgs-stable at all).
    nix-darwin-stable = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mylib.url = "path:/Users/dami/Developer/mylib";
  };

  outputs =
    inputs:
    (import ./lib/mkConfigurations.nix { inherit inputs; })
    // {
      formatter = {
        aarch64-darwin = inputs.nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
        x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      };
    };
}
