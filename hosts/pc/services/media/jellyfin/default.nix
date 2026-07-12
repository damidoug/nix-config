{
  host,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  services = {
    jellyfin = {
      enable = true;

      forceEncodingConfig = true;

      hardwareAcceleration = {
        enable = true;
        type = "vaapi";
        device = "/dev/dri/renderD128";
      };

      transcoding = {
        enableHardwareEncoding = true;
        throttleTranscoding = true;
        hardwareEncodingCodecs.hevc = true;
        hardwareDecodingCodecs = {
          h264 = true;
          hevc = true;
          hevc10bit = true;
          mpeg2 = true;
          vc1 = true;
          vp8 = true;
          vp9 = true;
          av1 = false;
        };
      };
    };

    seerr.enable = true;

    newt.blueprint.public-resources = {
      jellyfin = {
        name = "Jellyfin";
        protocol = "http";
        full-domain = "jellyfin.${host.extra.domain}";
        headers = [
          {
            name = "X-Forwarded-Protocol";
            value = "https";
          }
        ];
        targets = [
          {
            hostname = "localhost";
            method = "http";
            port = 8096;
            healthcheck = {
              hostname = "localhost";
              port = 8096;
              path = "/health";
            };
          }
        ];
      };

      seerr = {
        name = "Seerr";
        protocol = "http";
        full-domain = "seerr.${host.extra.domain}";
        headers = [
          {
            name = "X-Forwarded-Ssl";
            value = "on";
          }
        ];
        targets = [
          {
            hostname = "localhost";
            method = "http";
            port = config.services.seerr.port;
            healthcheck = {
              hostname = "localhost";
              port = config.services.seerr.port;
              path = "/api/v1/status";
            };
          }
        ];
      };
    };
  };

  networking.firewall.interfaces.${host.environment.networking.interface} = {
    allowedTCPPorts = [
      8096 # HTTP (main API + streaming)
      8920 # HTTPS
    ];
    allowedUDPPorts = [
      1900 # SSDP/UPnP discovery
      7359 # Jellyfin client discovery
    ];
  };

  systemd.services = {
    jellyfin.serviceConfig.UMask = mkForce "0007";
    seerr.environment.HOST = mkForce "127.0.0.1";
  };

  users.users.${config.services.jellyfin.user}.extraGroups = [
    "render"
    "video"
    "media"
    "downloads"
  ];
}
