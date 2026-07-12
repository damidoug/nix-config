{
  config,
  host,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
  location = "/data/photos";
in
{
  services = {
    immich = {
      enable = true;
      mediaLocation = location;
      host = "127.0.0.1";
      accelerationDevices = [
        "/dev/dri/renderD128"
        "/dev/kfd"
      ];
      machine-learning = {
        enable = true;
        environment = {
          # --- ROCm bypass for RX 580 (gfx803/Polaris, GCN 4) ------------------
          # Officially dropped in ROCm 6+, HSA override keeps it functional.
          HSA_OVERRIDE_GFX_VERSION = mkForce "8.0.3";
          ROC_ENABLE_PRE_VEGA = mkForce "1";
          HSA_USE_SVM = mkForce "0";
          # --- CPU fallback tuning (Ryzen 5 2600: 6c/12t) ----------------------
          MACHINE_LEARNING_MODEL_INTRA_OP_THREADS = mkForce "6";
          MACHINE_LEARNING_MODEL_INTER_OP_THREADS = mkForce "2";
        };
      };
      settings.server.externalDomain = "https://photos.${host.extra.domain}";
    };

    newt.blueprint.public-resources.immich = {
      name = "Immich";
      protocol = "http";
      full-domain = "photos.${host.extra.domain}";
      targets = [
        {
          hostname = "localhost";
          method = "http";
          port = config.services.immich.port;
          healthcheck = {
            hostname = "localhost";
            port = config.services.immich.port;
            path = "/api/server/ping";
          };
        }
      ];
    };
  };

  host.hardware.disk.folders = [
    {
      path = location;
      mode = "2770";
      group = config.services.immich.group;
    }
  ];

  systemd = {
    services = {
      immich-server = {
        unitConfig.RequiresMountsFor = [
          "/data"
          location
        ];
        serviceConfig = {
          Restart = mkForce "always";
          RestartSec = mkForce "5s";
          StateDirectoryMode = mkForce "0700";
        };
        unitConfig.StartLimitIntervalSec = mkForce 0;
      };

      immich-machine-learning = {
        serviceConfig.Restart = mkForce "always";
        serviceConfig.RestartSec = mkForce "15s";
        unitConfig.StartLimitIntervalSec = mkForce 0;
      };
    };
  };

  users.users.${config.services.immich.user}.extraGroups = [
    "video"
    "render"
  ];
}
