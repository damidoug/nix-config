{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
  inherit (config.host.environment.user)
    username
    fullName
    wheelNeedsPassword
    sshKeys
    ;
in
{
  config = {
    assertions = [
      {
        assertion = username != "";
        message = "host '${config.host.name}': host.environment.user.username must not be empty.";
      }
    ];

    programs.fish.enable = true;

    security = {
      sudo.enable = mkDefault false;
      sudo-rs = {
        enable = mkDefault true;
        execWheelOnly = mkDefault true;
        inherit wheelNeedsPassword;
      };
    };

    users = {
      defaultUserShell = pkgs.fish;

      users = {
        root.hashedPassword = mkDefault "!";

        ${username} = {
          description = if fullName != null then fullName else username;
          isNormalUser = true;
          initialHashedPassword = "$y$j9T$5ohu0kdM1nAelSruk3aWP0$JDX9qzN7mM7rsvNrbR0yHgLlhfYR/8F8IsJAV2H34..";
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = sshKeys;
        };
      };
    };
  };
}
