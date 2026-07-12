{ host, ... }:
let
  mediaFolders = [
    "movies"
    "animes"
    "tv"
  ];
in
{
  imports = [
    ./jellyfin
    ./qbittorrent
    ./servarr
  ];

  users = {
    groups.downloads = { };
    groups.media = { };
    users.${host.environment.user.username}.extraGroups = [
      "media"
      "downloads"
    ];
  };

  host.hardware.disk.folders =
    (map (folder: {
      path = "/data/${folder}";
      mode = "2770";
      group = "media";
    }) mediaFolders)
    ++ [
      {
        path = "/data/downloads";
        mode = "2770";
        group = "downloads";
      }
    ];
}
