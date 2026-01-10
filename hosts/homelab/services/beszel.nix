{ config, ... }:
{
  age.secrets.beszel.file = ../secrets/beszel.age;

  services.beszel = {
    agent = {
      enable = true;
      environmentFile = config.age.secrets.beszel.path;
    };
    hub = {
      enable = true;
      environmentFile = config.age.secrets.beszel.path;
    };
  };

  services.nginx.virtualHosts."beszel.damidoug.dev".locations."/" = {
    proxyPass = "http://localhost:${toString config.services.beszel.hub.port}/";
    extraConfig = ''
      client_max_body_size 10M;
      proxy_read_timeout 360s;
    '';
  };
}
