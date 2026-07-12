{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
  inherit (config.host.hardware.boot) efiSupport efiMountPoint;
in
{
  config = {
    boot = {
      tmp.cleanOnBoot = true;

      kernelPackages = pkgs.linuxPackages_latest;

      kernelParams = [
        "quiet"
        "splash"
      ];

      initrd = {
        availableKernelModules = [
          "ahci"
          "nvme"
          "xhci_pci"
          "usb_storage"
          "usbhid"
          "sd_mod"
          "sr_mod"
          "virtio_pci"
          "virtio_scsi"
        ];

        systemd.network.wait-online.enable = mkDefault false;
      };

      loader = {
        efi = {
          canTouchEfiVariables = efiSupport;
          efiSysMountPoint = efiMountPoint;
        };

        grub = {
          enable = true;
          inherit efiSupport;
          devices = [ "nodev" ];
          configurationLimit = 20;
        };
      };
    };

    services.fwupd.enable = true;
  };
}
