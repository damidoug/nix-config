{
  config,
  host,
  lib,
  ...
}:
let
  inherit (lib) mkForce;

  cfg = {
    server.bindaddress = "127.0.0.1";
    log.level = "info";
    analytics.enabled = false;
  };
in
{
  services = {
    flaresolverr.enable = true;

    prowlarr = {
      enable = true;
      settings = cfg;
    };

    radarr = {
      enable = true;
      settings = cfg;
    };

    sonarr = {
      enable = true;
      settings = cfg;
    };

    newt.blueprint.public-resources = {
      prowlarr = {
        name = "Prowlarr";
        protocol = "http";
        full-domain = "prowlarr.${host.extra.domain}";
        auth.sso-enabled = true;
        targets = [
          {
            hostname = "localhost";
            method = "http";
            port = config.services.prowlarr.settings.server.port;
            healthcheck = {
              hostname = "localhost";
              port = config.services.prowlarr.settings.server.port;
              path = "/ping";
            };
          }
        ];
      };

      radarr = {
        name = "Radarr";
        protocol = "http";
        full-domain = "radarr.${host.extra.domain}";
        auth.sso-enabled = true;
        targets = [
          {
            hostname = "localhost";
            method = "http";
            port = config.services.radarr.settings.server.port;
            healthcheck = {
              hostname = "localhost";
              port = config.services.radarr.settings.server.port;
              path = "/ping";
            };
          }
        ];
      };

      sonarr = {
        name = "Sonarr";
        protocol = "http";
        full-domain = "sonarr.${host.extra.domain}";
        auth.sso-enabled = true;
        targets = [
          {
            hostname = "localhost";
            method = "http";
            port = config.services.sonarr.settings.server.port;
            healthcheck = {
              hostname = "localhost";
              port = config.services.sonarr.settings.server.port;
              path = "/ping";
            };
          }
        ];
      };
    };
  };

  users.users = {
    ${config.services.radarr.user}.extraGroups = [
      "media"
      "downloads"
    ];
    ${config.services.sonarr.user}.extraGroups = [
      "media"
      "downloads"
    ];
  };

  systemd.services = {
    flaresolverr.environment.HOST = mkForce "127.0.0.1";
    prowlarr.serviceConfig = {
      UMask = mkForce "0007";
      StateDirectoryMode = mkForce "0700";
    };
    radarr.serviceConfig = {
      UMask = mkForce "0007";
      StateDirectoryMode = mkForce "0700";
    };
    sonarr.serviceConfig = {
      UMask = mkForce "0007";
      StateDirectoryMode = mkForce "0700";
    };
  };
}
