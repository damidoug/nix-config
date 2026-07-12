{
  config,

  ...
}:
let
  net = config.host.environment.networking;
  name = config.host.name;
in
{
  config = {
    networking = {
      hostName = name;
      computerName = name;
      localHostName = name;

      inherit (net) dns;

      wakeOnLan.enable = false;

      knownNetworkServices = [
        "Wi-Fi"
        "Thunderbolt Bridge"
      ];

      applicationFirewall = {
        enable = true;
        enableStealthMode = true;
        allowSigned = true;
        allowSignedApp = true;
        blockAllIncoming = false;
      };
    };
  };
}
