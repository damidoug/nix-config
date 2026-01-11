{ pkgs, ... }:
{
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    intel-gpu-tools.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # VA-API (iHD) userspace
        vpl-gpu-rt # oneVPL (QSV) runtime
        intel-compute-runtime # OpenCL (NEO) + Level Zero for Arc/Xe
      ];
    };
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"; # Use the modern VA-API driver

  boot.kernelParams = [ "i915.enable_guc=2" ];
  boot.kernelModules = [ "kvm-intel" ];

  # May help services that have trouble accessing /dev/dri (e.g., jellyfin/plex):
  users.users.homelab.extraGroups = [
    "video"
    "render"
  ];
}
