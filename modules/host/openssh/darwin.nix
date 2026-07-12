{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (config.host.environment) user;
in
{
  # nix-darwin's services.openssh is far more minimal than NixOS's: no
  # `.settings` submodule, no `openFirewall`, no fail2ban at all. `enable`
  # toggles Apple's built-in Remote Login service via `systemsetup`; the only
  # way to add sshd_config directives is the raw `extraConfig` string, written
  # to /etc/ssh/sshd_config.d/100-nix-darwin.conf. See
  # https://github.com/nix-darwin/nix-darwin/blob/master/modules/services/openssh.nix
  config = mkIf (user.sshKeys != [ ]) {
    services.openssh = {
      enable = true;

      extraConfig = ''
        PermitRootLogin no
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        MaxAuthTries 5
        ClientAliveInterval 60
        ClientAliveCountMax 3
        X11Forwarding no
        AllowAgentForwarding no
        GatewayPorts no
        AllowTcpForwarding no
        Compression no
        UseDNS no
        PrintMotd no
      '';
    };
  };
}
