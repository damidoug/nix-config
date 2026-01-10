{ config, ... }:
{
  services.radarr = {
    enable = true;
    group = "media";
  };

  services.nginx.virtualHosts."radarr.damidoug.dev".locations."/".proxyPass =
    "http://localhost:${toString config.services.radarr.settings.server.port}/";
}
