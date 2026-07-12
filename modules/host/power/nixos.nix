{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (config.host) isServer isLaptop;

  server = {
    services.logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "ignore";
      HandleRebootKey = "ignore";

      HandleSuspendKey = "ignore";
      HandleHibernateKey = "ignore";

      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";

      LidSwitchIgnoreInhibited = "no";

      IdleAction = "ignore";
      IdleActionSec = "30min";
    };

    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };

  desktop = {
    services.logind.settings.Login = {
      HandlePowerKey = "poweroff";
      HandlePowerKeyLongPress = "poweroff";
      HandleRebootKey = "reboot";

      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";

      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";

      LidSwitchIgnoreInhibited = "yes";

      IdleAction = "ignore";
      IdleActionSec = "30min";
    };
  };

  laptop = {
    services = {
      logind.settings.Login = {
        HandlePowerKey = "poweroff";
        HandlePowerKeyLongPress = "poweroff";
        HandleRebootKey = "reboot";

        HandleSuspendKey = "suspend";
        HandleHibernateKey = "hibernate";

        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        HandleLidSwitchDocked = "ignore";

        LidSwitchIgnoreInhibited = "yes";

        IdleAction = "suspend";
        IdleActionSec = "30min";
      };

      tlp = {
        enable = true;

        settings = {
          START_CHARGE_THRESH_BAT0 = 40;
          STOP_CHARGE_THRESH_BAT0 = 80;

          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

          WIFI_PWR_ON_BAT = "on";
        };
      };
    };
  };
in
{
  # A bare top-level `config = if isServer then server else ...;` creates an
  # infinite recursion here: NixOS needs to know the set of keys each module
  # contributes before it can merge configs, and a raw `if` between
  # differently-shaped attrsets forces `isServer` (hence `config.host`) just
  # to determine that shape — while `config.host` is itself part of the same
  # merge being computed. `mkMerge`/`mkIf` sidestep this: their key set is
  # known without evaluating the condition.
  config = mkMerge [
    (mkIf isServer server)
    (mkIf (isLaptop && !isServer) laptop)
    (mkIf (!isServer && !isLaptop) desktop)
  ];
}
