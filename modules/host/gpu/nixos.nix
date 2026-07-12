{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;

  inherit (config.host.hardware) gpu;
  inherit (config.host.environment) user desktop;

  enabledVendors = lib.filterAttrs (_: v: v != null) gpu;
  vendorNames = builtins.attrNames enabledVendors;
  vendor = if vendorNames == [ ] then null else builtins.head vendorNames;

  legacyGPU =
    if vendor == "amd" then
      gpu.amd.legacy
    else if vendor == "nvidia" then
      gpu.nvidia.legacy
    else
      false;

  gpuForceProbeId = if vendor == "intel" then gpu.intel.probe else null;

  gpuPackages = {
    amd = {
      graphics =
        if legacyGPU then
          [ pkgs.mesa.opencl ]
        else
          [
            pkgs.rocmPackages.clr
            pkgs.rocmPackages.clr.icd
          ];

      tools = [
        pkgs.clinfo
      ]
      ++ optionals (!legacyGPU) [
        pkgs.rocmPackages.rocminfo
        pkgs.rocmPackages.rocm-smi
      ];
    };

    intel = {
      graphics = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        intel-compute-runtime
      ];

      tools = with pkgs; [
        clinfo
        intel-gpu-tools
      ];
    };

    nvidia = {
      graphics = with pkgs; [
        nvidia-vaapi-driver
      ];

      tools = [ ];
    };
  };

  graphics32 = {
    amd = [ ];

    intel = with pkgs.driversi686Linux; [
      intel-media-driver
    ];

    nvidia = [ ];
  };

  variables = {
    amd = {
      AMD_VULKAN_ICD = "RADV";
    };

    intel = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    nvidia = {
      LIBVA_DRIVER_NAME = "nvidia";
    };
  };

  commonTools = with pkgs; [
    vulkan-tools
    mesa-demos
    pciutils
    nvtopPackages.full
    libva-utils
  ];
in
{
  config = {
    assertions = [
      {
        assertion = vendorNames != [ ];
        message = "host '${config.host.name}': at least one host.hardware.gpu.{amd,intel,nvidia} must be set — required for graphics drivers/packages.";
      }
      {
        assertion = builtins.length vendorNames <= 1;
        message = "host '${config.host.name}': only one host.hardware.gpu vendor can be enabled at a time (got: ${toString vendorNames}) — a host can't have two GPU vendors configured simultaneously.";
      }
    ];

    boot = {
      initrd.kernelModules = mkIf (vendor == "amd") [
        "amdgpu"
      ];

      kernelParams =
        optionals (vendor == "amd" && legacyGPU) [
          "amdgpu.si_support=1"
          "radeon.si_support=0"
          "amdgpu.cik_support=1"
          "radeon.cik_support=0"
        ]
        ++ optionals (vendor == "intel") [
          "i915.enable_guc=3"
        ]
        ++ optionals (vendor == "intel" && gpuForceProbeId != null) [
          "i915.force_probe=${gpuForceProbeId}"
        ];
    };

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;

        extraPackages = gpuPackages.${vendor}.graphics;
        extraPackages32 = graphics32.${vendor};
      };

      nvidia = mkIf (vendor == "nvidia") {
        modesetting.enable = true;
        open = !legacyGPU;
        nvidiaSettings = desktop != null;
      };
    };

    services.xserver.videoDrivers = mkIf (vendor == "nvidia") [
      "nvidia"
    ];

    environment = {
      variables = variables.${vendor};

      systemPackages = commonTools ++ gpuPackages.${vendor}.tools;
    };

    users.users.${user.username}.extraGroups = [
      "video"
      "render"
    ];
  };
}
