{
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
      grub = {
        configurationLimit = 20;
        devices = [ "nodev" ];
        efiSupport = true;
      };
    };
    tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
      tmpfsSize = "50%";
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
      "sd_mod"
    ];
    kernelParams = [ "libata.force=noncq" ];
  };

  zramSwap.enable = true;

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096; # 4GB (Change to 8192 when you get 16GB RAM)
    }
  ];
}
