{ config, ... }:
{
  services.adguardhome = {
    enable = false;
    host = "127.0.0.1";
    port = 3003;
    settings = {
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        safe_search.enabled = false;
      };
      # The following notation uses map
      # to not have to manually create {enabled = true; url = "";} for every filter
      # This is, however, fully optional
      filters =
        map
          (url: {
            enabled = true;
            url = url;
          })
          [
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
            "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
          ];
    };
  };

  services.nginx.virtualHosts."adguard.damidoug.dev".locations."/".proxyPass =
    "http://localhost:${toString config.services.adguardhome.port}/";

  # networking.firewall.allowedTCPPorts = [ 53 ];
  # networking.firewall.allowedUDPPorts = [ 53 ];
}
