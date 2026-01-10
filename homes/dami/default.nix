{ pkgs, ... }:
{
  imports = [
    ./apps
    ./dev
    ./shell
  ];

  programs.home-manager.enable = true;

  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
    hinting = "slight";
  };

  targets.genericLinux.enable = !(pkgs.stdenv.isDarwin || builtins.pathExists "/etc/NIXOS");

  xdg.enable = true;

  home.stateVersion = "25.11";
}
