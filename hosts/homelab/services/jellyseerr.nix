{ config, ... }:
{
  services.jellyseerr.enable = true;

  services.nginx.virtualHosts."seerr.damidoug.dev".locations."/".proxyPass =
    "http://localhost:${toString config.services.jellyseerr.port}/";
}
