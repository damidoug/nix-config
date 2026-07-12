{
  pkgs,
  host,
  lib,
  ...
}:
{
  imports = [
    ./lutris
    ./mangohud
    ./steam
  ];

  boot.kernel.sysctl."vm.max_map_count" = lib.mkForce 2097152;

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Performance mode on'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Performance mode off'";
      };
    };
  };

  hardware.xpadneo.enable = true;

  users.users.${host.environment.user.username}.extraGroups = [ "gamemode" ];

  host.hardware.disk.folders = [
    {
      path = "/games";
      user = host.environment.user.username;
      group = host.environment.user.username;
    }
  ];
}
