{
  config,
  lib,
  host,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce;
  qbt = config.services.qbittorrent;
  incompleteDir = "${qbt.profileDir}/incomplete";
  completeDir = "/data/downloads";

  vpn = "torrent-vpn";
  vpnAddress = "10.71.134.159";
  publicKey = "Sa9fFFthvihGMO4cPExJ7ZaWSHNYoXmOqZMvJsaxOVk=";
  endpoint = "178.249.211.66:51820";
  ip = "${pkgs.iproute2}/bin/ip";
in
{
  age.secrets = {
    ${vpn}.file = ./vpn.age;
    qui = {
      file = ./qui.age;
      owner = config.services.qui.user;
    };
  };

  networking.wg-quick.interfaces.${vpn} = {
    autostart = true;
    address = [ "${vpnAddress}/32" ];
    privateKeyFile = config.age.secrets.${vpn}.path;
    table = "off";
    peers = [
      {
        inherit publicKey endpoint;
        allowedIPs = [ "0.0.0.0/0" ];
      }
    ];
    postUp = "${ip} -4 rule add from ${vpnAddress} table 42\n${ip} -4 route add default dev ${vpn} table 42";
    postDown = "${ip} -4 rule del from ${vpnAddress} table 42\n${ip} -4 route del default dev ${vpn} table 42";
  };

  services = {
    qbittorrent = {
      enable = true;
      serverConfig = {
        LegalNotice.Accepted = true;
        BitTorrent.Session = {
          DefaultSavePath = completeDir;
          TempPath = incompleteDir;
          TempPathEnabled = true;
          MaxRatio = 0;
          MaxRatioAction = 1; # 0 = pause, 1 = remove
          MaxSeedingTime = -1;
          MaxSeedingTimeAction = 0;
          MaxActiveDownloads = 5;
          MaxActiveTorrents = 5;
          MaxActiveUploads = 0;
          MaxConnections = 300;
          MaxConnectionsPerTorrent = 60;
          MaxUploads = 0;
          MaxUploadsPerTorrent = 0;
          # explicit write cache for NVMe — reduces flush overhead on piece writes
          DiskWriteCacheSize = 512; # MiB
          DiskWriteCacheTTL = 60; # seconds
          # Automatic Torrent Management — keep ATM active on changes so torrents relocate
          DisableAutoTMMByDefault = false;
          AutoTMMRetainedWhenCategoryChanged = true;
          AutoTMMRetainedWhenDefaultSavePathChanged = true;
          AutoTMMRetainedWhenCategorySavePathChanged = true;
        };
        Preferences = {
          Connection = {
            Interface = vpn;
            InterfaceAddress = vpnAddress;
            InterfaceName = vpn;
          };
          Downloads = {
            SavePath = completeDir;
            TempPath = incompleteDir;
            TempPathEnabled = true;
            # preallocate full file before download — qBittorrent refuses to start
            # if there is not enough free space, protecting the NVMe from overfill
            PreAllocation = true;
          };
          WebUI = {
            Address = "127.0.0.1";
            LocalHostAuth = false;
            CSRFProtection = true;
            ClickjackingProtection = true;
            SecureCookie = true;
          };
        };
      };
    };

    qui = {
      enable = true;
      secretFile = config.age.secrets.qui.path;
      settings = {
        host = "127.0.0.1";
        checkForUpdates = false;
      };
    };

    newt.blueprint.public-resources.torrent = {
      name = "Torrent";
      protocol = "http";
      full-domain = "torrent.${host.extra.domain}";
      auth.sso-enabled = true;
      targets = [
        {
          hostname = "localhost";
          method = "http";
          port = config.services.qui.settings.port;
          healthcheck = {
            hostname = "localhost";
            port = config.services.qui.settings.port;
            path = "/health";
          };
        }
      ];
    };
  };

  users.users = {
    ${config.services.qbittorrent.user}.extraGroups = [ "downloads" ];
    ${config.services.qui.user}.extraGroups = [ "downloads" ];
  };

  systemd.services = {
    qbittorrent = {
      requires = [ "wg-quick-${vpn}.service" ];
      after = [ "wg-quick-${vpn}.service" ];
      serviceConfig = {
        UMask = mkForce "0007";
        StateDirectoryMode = mkForce "0700";
        PrivateTmp = mkForce true;
        ReadWritePaths = mkForce [
          qbt.profileDir
          completeDir
        ];
      };
    };

    qui = {
      requires = [ "qbittorrent.service" ];
      after = [ "qbittorrent.service" ];
      serviceConfig.UMask = mkForce "0007";
    };
  };
}
