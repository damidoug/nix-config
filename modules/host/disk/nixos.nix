{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) optionals mkDefault;

  inherit (config.host.hardware) disk;
  inherit (config.host) isQemu;

  isBtrfs = disk.fileSystem == "btrfs";
  isSSD = disk.type == "ssd";
  isNVMe = disk.type == "nvme";
in
{
  config = {
    assertions = [
      {
        assertion = disk.type != null;
        message = "host '${config.host.name}': host.hardware.disk.type must be set (ssd, nvme, or hdd) — required for scrub/trim/smartd defaults.";
      }
      {
        assertion = disk.fileSystem != null;
        message = "host '${config.host.name}': host.hardware.disk.fileSystem must be set (ext4 or btrfs).";
      }
      {
        # disko is injected unconditionally for every Linux host (see
        # lib/mkConfigurations.nix) — this is the assertion that used to be
        # gated behind capabilities.disko there; it lives here now since
        # disk/nixos.nix already owns every other disk-related check.
        assertion = (disk.disko.devices.disk or { }) != { };
        message = "host '${config.host.name}': host.hardware.disk.disko.devices.disk is empty — this host has no disk topology configured and will not be installable.";
      }
    ];

    services = {
      btrfs.autoScrub = {
        enable = mkDefault isBtrfs;
        interval = mkDefault "weekly";
        fileSystems = mkDefault [ "/" ];
      };

      # QEMU/KVM virtual disks (host.type includes "qemu") have no SMART
      # passthrough at all — smartd defaults off for them, on for everything
      # else. Still mkDefault, so a host can override either way.
      smartd = {
        enable = mkDefault (!isQemu);
        autodetect = true;
      };

      fstrim = {
        enable = mkDefault (isSSD || isNVMe);
        interval = mkDefault "weekly";
      };
    };

    inherit (disk) disko;

    systemd.tmpfiles.rules = map (f: "d ${f.path} ${f.mode} ${f.user} ${f.group} - -") disk.folders;

    environment.systemPackages =
      with pkgs;
      [
        smartmontools
        duf
        parted
      ]
      ++ optionals isBtrfs [
        btrfs-progs
        compsize
        btdu
      ]
      ++ optionals isNVMe [
        nvme-cli
      ]
      ++ optionals (!isNVMe) [
        hdparm
      ];
  };
}
