{
  networking = {
    hostName = "homelab";

    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      ethernet.macAddress = "preserve";
      wifi = {
        backend = "iwd";
        macAddress = "random";
        powersave = false;
      };
    };

    useDHCP = false;
    dhcpcd.enable = false;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        8096
        8920
      ];
      allowedUDPPorts = [
        1900
        7359
      ];
    };
  };

  services.resolved = {
    enable = true;
    fallbackDns = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    dnssec = "allow-downgrade";
    extraConfig = "DNSStubListener=no";
  };

  users.users.homelab.extraGroups = [ "networkmanager" ];
}
