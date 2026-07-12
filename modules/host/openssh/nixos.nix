{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.host.environment) user;
in
{
  # See ./darwin.nix for the much more minimal nix-darwin equivalent — no
  # `.settings` submodule, no `openFirewall`, no fail2ban there at all.
  config = mkIf (user.sshKeys != [ ]) {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";

        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;

        MaxAuthTries = 5;

        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;

        X11Forwarding = false;

        AllowAgentForwarding = "no";

        GatewayPorts = "no";

        AllowTcpForwarding = "no";

        Compression = false;

        UseDns = false;

        PrintMotd = false;
      };
    };

    services.fail2ban = {
      enable = true;
      bantime = "24h";
      maxretry = 5;
      ignoreIP = [
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
      bantime-increment = {
        enable = true;
        formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
        maxtime = "168h";
        overalljails = true;
      };

      jails.sshd.settings.mode = "aggressive";
    };
  };
}
