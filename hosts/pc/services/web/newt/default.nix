{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  age.secrets.newt.file = ./secrets.age;

  services.newt = {
    enable = true;
    environmentFile = config.age.secrets.newt.path;
  };

  systemd.services.newt = {
    serviceConfig = {
      Restart = mkForce "always";
      RestartSec = mkForce "10s";
    };
    unitConfig.StartLimitIntervalSec = mkForce 0;
  };
}
