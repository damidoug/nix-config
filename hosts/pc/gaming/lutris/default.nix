{
  host,
  config,
  ...
}:
{
  home-manager.users.${host.environment.user.username}.programs.lutris = {
    enable = true;
    steamPackage = config.programs.steam.package;
    protonPackages = config.programs.steam.extraCompatPackages;
  };
}
