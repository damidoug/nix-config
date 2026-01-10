{ config, pkgs, ... }:
{
  programs.go = {
    enable = true;
    telemetry.mode = "off";
    env.GOPATH = "${config.home.homeDirectory}/Developer/go";
  };

  home.packages = [ pkgs.air ];
}
