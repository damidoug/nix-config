{ pkgs, lib, ... }:
{
  home.packages = lib.mkIf pkgs.stdenv.isDarwin [ pkgs.monitorcontrol ];
}
