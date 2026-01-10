{ config, ... }:
{
  services.sonarr = {
    enable = true;
    group = "media";
  };

  services.nginx.virtualHosts."sonarr.damidoug.dev".locations."/".proxyPass =
    "http://localhost:${toString config.services.sonarr.settings.server.port}/";
}
