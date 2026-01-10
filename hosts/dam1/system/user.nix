{ pkgs, ... }:
{
  programs.fish.enable = true;

  users = {
    knownUsers = [ "dami" ];
    users.dami = {
      description = "Douglas Damiano";
      home = "/Users/dami";
      shell = pkgs.fish;
      uid = 501;
    };
  };
}
