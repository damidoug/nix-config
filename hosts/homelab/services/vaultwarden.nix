{ config, ... }:
{
  age.secrets.vaultwarden = {
    file = ../secrets/vaultwarden.age;
    owner = "vaultwarden";
    group = "vaultwarden";
  };

  services.vaultwarden = {
    enable = true;
    environmentFile = config.age.secrets.vaultwarden.path;
  };

  services.nginx.virtualHosts."vault.damidoug.dev".locations."/" = {
    proxyPass = "http://localhost:8222/";
    proxyWebsockets = true;
  };
}
