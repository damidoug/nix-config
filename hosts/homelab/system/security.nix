{ inputs, pkgs, ... }:
{
  security.sudo.enable = false;
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    banner = ''
      **************************************************
      *                 HOMELAB SERVER                 *
      **************************************************
      *  Authorized access only.                       *
      *  All connections are monitored and logged.     *
      *                                                *
      *  If you are not authorized, disconnect now.    *
      **************************************************
    '';
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  environment.systemPackages = [
    inputs.agenix.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];
}
