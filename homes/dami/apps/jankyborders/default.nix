{ pkgs, lib, ... }:
{
  home.packages = lib.mkIf pkgs.stdenv.isDarwin [ pkgs.jankyborders ];

  programs.aerospace.settings.after-startup-command = [
    "exec-and-forget ${lib.getExe pkgs.jankyborders} active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0"
  ];
}
