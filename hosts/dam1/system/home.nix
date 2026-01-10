{ inputs, ... }:
{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "old";
    users.dami = ../../../homes/dami;
    extraSpecialArgs = { inherit inputs; };
  };
}
