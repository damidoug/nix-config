{ config, pkgs, ... }:
let
  torrent-indexer = pkgs.buildGoModule {
    pname = "torrent-indexer";
    version = "latest";

    src = pkgs.fetchFromGitHub {
      owner = "felipemarinho97";
      repo = "torrent-indexer";
      rev = "main";
      sha256 = "1lxzz3spsjs5md5dw7k06w1znjhbfnvapkpyhnwj68lfzdwq093p";
    };

    vendorHash = "sha256-kOlrbUOzYQDepvgQKU+y0IMZ/hzPHVdbUGaKL0gf0EI=";

    doCheck = false;

    meta = with pkgs.lib; {
      description = "Simple torrent indexer for Brazilian websites";
      homepage = "https://github.com/felipemarinho97/torrent-indexer";
      license = licenses.mit;
    };
  };
in
{
  environment.systemPackages = [ torrent-indexer ];
  services.flaresolverr.enable = true;
  services.prowlarr.enable = true;

  services.nginx.virtualHosts = {
    "prowlarr.damidoug.dev".locations."/".proxyPass =
      "http://localhost:${toString config.services.prowlarr.settings.server.port}/";
  };

  services.redis.servers.torrent-indexer = {
    enable = true;
    port = 6379;
    settings = {
      maxmemory = "256mb";
      maxmemory-policy = "allkeys-lru";
    };
  };

  systemd.services.torrent-indexer = {
    description = "Torrent Indexer Service";
    after = [
      "network.target"
      "redis-torrent-indexer.service"
    ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      # 1. NETWORK
      PORT = "8080"; # Matches your Nginx/Prowlarr config
      METRICS_PORT = "8081"; # Ready for monitoring

      # 2. REDIS CONNECTION
      # The app adds ":6379" automatically, so we just give the host.
      REDIS_HOST = "localhost";

      # 3. MEMORY OPTIMIZATION (Crucial for 8GB RAM)
      # Reduce cache time from 7 days to 48 hours to save RAM/Disk
      LONG_LIVED_CACHE_EXPIRATION = "48h";
      SHORT_LIVED_CACHE_EXPIRATION = "30m";

      # 4. LOGGING
      LOG_LEVEL = "1"; # 1 = Info (Clean logs)
      LOG_FORMAT = "console"; # Easier to read in journalctl
    };

    serviceConfig = {
      ExecStart = "${torrent-indexer}/bin/torrent-indexer";
      DynamicUser = true;

      # SAFETY NETS (Keep these!)
      Restart = "always";
      RestartSec = "10s";
      MemoryHigh = "800M"; # Throttle if it gets heavy
      MemoryMax = "1G"; # Kill if it gets dangerous
    };
  };
}
