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
      "ehci_pci"
      "ahci"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
    kernelParams = [ "libata.force=noncq" ];
  };
}
