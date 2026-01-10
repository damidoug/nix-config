{
  # Enable general power management settings
  powerManagement.enable = true;

  services = {
    # Use TLP for battery charge management
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        # Set battery charge thresholds (60–80%)
        START_CHARGE_THRESH_BAT0 = 60;
        STOP_CHARGE_THRESH_BAT0 = 80;

        # Optional: enable TLP power saving for non-critical devices
        DISK_IDLE_SECS = 0; # avoid spinning down disks
        SATA_LINKPWR_ON_AC = "max_performance";
        SATA_LINKPWR_ON_BAT = "max_performance";
      };
    };

    # Disable logind's handling of lid switch events
    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    thermald.enable = true;
  };

  # Disable systemd sleep targets to prevent sleep, suspend, hibernate, and hybrid-sleep
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
}
