{ pkgs, lib, ... }:
{
  programs.mpv.enable = pkgs.stdenv.isLinux;

  home.packages = lib.mkIf pkgs.stdenv.isDarwin [ pkgs.iina ];
}
