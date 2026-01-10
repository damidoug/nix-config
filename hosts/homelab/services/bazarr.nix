{ config, ... }:
{
  services.bazarr = {
    enable = true;
    group = "media";
  };

  services.nginx.virtualHosts."bazarr.damidoug.dev".locations."/".proxyPass =
    "http://localhost:${toString config.services.bazarr.listenPort}/";
}
