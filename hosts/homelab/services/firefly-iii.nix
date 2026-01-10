{ config, ... }:
{
  services.firefly-iii = {
    enable = true;
    enableNginx = true;
    settings = {
      APP_ENV = "production";
      SITE_OWNER = "contact@damidoug.dev";
      APP_KEY_FILE = "UpAj44cTeY57EdqUEjZZmGFlzlvzT7JDWSl7PYn2vxM=";
      DEFAULT_LANGUAGE = "en_US";
      TZ = "Europe/Malta";
      DB_CONNECTION = "pgsql";
      DB_HOST = "db";
      DB_PORT = 3306;
      DB_DATABASE = "firefly";
      DB_USERNAME = "firefly";
      DB_PASSWORD_FILE = "/var/secrets/firefly-iii-mysql-password.txt";
      REDIS_SCHEME = "tcp";
      # use only when using 'unix' for REDIS_SCHEME. Leave empty otherwise.
      REDIS_PATH = "";
      # use only when using 'tcp' or 'http' for REDIS_SCHEME. Leave empty otherwise.
      REDIS_HOST = "127.0.0.1";
      REDIS_PORT = "6379";
      REDIS_USERNAME = "firefly";
      REDIS_PASSWORD_FILE = "/var/secrets/firefly-iii-mysql-password.txt";
    };
  };

  services.nginx.virtualHosts."radarr.damidoug.dev".locations."/".proxyPass =
    "http://localhost:${toString config.services.radarr.settings.server.port}/";
}
