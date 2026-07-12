{
  config,
  pkgs,
  ...
}:
let
  inherit (config.host.environment.user)
    username
    fullName
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

    users = {
      knownUsers = [ username ];

      users.${username} = {
        home = "/Users/${username}";
        shell = pkgs.fish;
        uid = 501;
        description = if fullName != null then fullName else username;
        openssh.authorizedKeys.keys = sshKeys;
      };
    };

    system.primaryUser = username;
  };
}
