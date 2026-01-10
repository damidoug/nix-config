{ config, ... }:
{
  services.flood.enable = true;

  services.nginx.virtualHosts."flood.damidoug.dev".locations."/".proxyPass =
    "http://localhost:${toString config.services.flood.port}/";

  systemd.services.flood.serviceConfig.SupplementaryGroups = [ "media" ];
}
