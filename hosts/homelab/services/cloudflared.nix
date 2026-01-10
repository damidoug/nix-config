{ config, ... }:
{
  age.secrets.cloudflared.file = ../secrets/cloudflared.age;

  services.cloudflared = {
    enable = true;
    tunnels."homelab-tunnel" = {
      credentialsFile = "${config.age.secrets.cloudflared.path}";
      default = "http_status:404";
      ingress."*.damidoug.dev" = "http://localhost:80";
    };
  };
}
