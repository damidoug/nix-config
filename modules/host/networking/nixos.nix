{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  net = config.host.environment.networking;

  mac = if config.host.isServer then "stable" else "random";
  powersave = config.host.isLaptop;
in
{
  config = {
    assertions = [
      {
        assertion = net.networkd.enable -> net.interface != null;
        message = "host '${config.host.name}': environment.networking.networkd.enable is true but environment.networking.interface is unset — systemd-networkd has nothing to match against.";
      }
      {
        assertion = net.networkd.enable -> net.networkd.static.addresses != [ ];
        message = "host '${config.host.name}': environment.networking.networkd.enable is true but environment.networking.networkd.static.addresses is empty — this host would come up with no address.";
      }
    ];

    networking = {
      hostName = config.host.name;

      firewall.enable = true;
      nftables.enable = true;

      nameservers = net.dns;

      useNetworkd = net.networkd.enable;
      useDHCP = false;
      dhcpcd.enable = false;

      networkmanager = {
        enable = !net.networkd.enable;
        dns = if net.dns != [ ] then "none" else "default";
        ethernet.macAddress = mac;
        wifi = {
          backend = "iwd";
          macAddress = mac;
          inherit powersave;
        };
      };
    };

    systemd.network = mkIf net.networkd.enable {
      enable = true;

      networks."10-wan" = {
        matchConfig.Name = net.interface;

        networkConfig.DHCP = "no";

        address = net.networkd.static.addresses;
        routes = net.networkd.static.routes;
      };
    };

    users.users.${config.host.environment.user.username}.extraGroups = mkIf (!net.networkd.enable) [
      "networkmanager"
    ];
  };
}
