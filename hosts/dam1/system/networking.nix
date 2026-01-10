{
  networking = {
    applicationFirewall = {
      enable = true;
      enableStealthMode = true;
      allowSigned = true;
      allowSignedApp = true;
      blockAllIncoming = false;
    };
    dns = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
    knownNetworkServices = [
      "AX88179B"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ];
    wakeOnLan.enable = false;
  };

  services.openssh.enable = false;
}
