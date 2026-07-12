{ config, ... }:
let
  inherit (config.host.hardware) cpu;

  tempSensorModule = {
    intel = "coretemp";
    amd = "k10temp";
  };

  pstateDriver = {
    intel = "intel_pstate";
    amd = "amd_pstate";
  };
in
{
  config = {
    assertions = [
      {
        assertion = cpu != null;
        message = "host '${config.host.name}': host.hardware.cpu must be set (intel or amd) — required for microcode updates and CPU-specific kernel modules.";
      }
    ];

    boot = {
      kernelModules = [
        "kvm-${cpu}"
        tempSensorModule.${cpu}
      ];
      kernelParams = [ "${pstateDriver.${cpu}}=active" ];
    };

    hardware = {
      enableRedistributableFirmware = true;
      cpu.${cpu}.updateMicrocode = true;
    };

    powerManagement = {
      enable = true;
      powertop.enable = true;
      cpuFreqGovernor = "schedutil";
    };

    services.irqbalance.enable = true;
  };
}
