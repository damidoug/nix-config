{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    {
      # ── Battery Toolkit ───────────────────────────────────────────────────
      # Best available charge limiter for Apple Silicon on pre-Tahoe macOS.
      # Tahoe 26.4+ has native charge limiting but only at fixed 80% until further updates.
      environment.systemPackages = [ pkgs.battery-toolkit ];

      system.defaults = {
        CustomUserPreferences."me.mhaeuser.BatteryToolkit" = {
          autostart = false; # managed by launchd agent below instead
        };
        CustomSystemPreferences."me.mhaeuser.batterytoolkitd" = {
          AdapterSleep = 0;
          MagSafeSync = 0;
          MaxCharge = 80;
          MinCharge = 20;
          PreviousSleepDisabled = 0;
        };
      };

      # Keep Battery Toolkit alive as a user agent
      launchd.agents.battery-toolkit.serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-W"
          "${pkgs.battery-toolkit}/Applications/Battery Toolkit.app"
        ];
        StandardOutPath = "/tmp/battery-toolkit.log";
        StandardErrorPath = "/tmp/battery-toolkit.log";
        KeepAlive = true;
        RunAtLoad = true;
      };

      # ── Power management via pmset ────────────────────────────────────────
      # Activation script applies on darwin-rebuild switch; launchd daemon re-applies
      # on every boot because macOS (Tahoe+) resets pmset settings after reboots.
      system.activationScripts.pmset.text = ''
        /usr/bin/pmset -b displaysleep 10 sleep 20 disksleep 10 powernap 0
        /usr/bin/pmset -c displaysleep 30 sleep 0 disksleep 10 powernap 0 womp 0
      '';

      launchd.daemons.pmset-config.serviceConfig = {
        Label = "me.dami.pmset-config";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/usr/bin/pmset -b displaysleep 10 sleep 20 disksleep 10 powernap 0; /usr/bin/pmset -c displaysleep 30 sleep 0 disksleep 10 powernap 0 womp 0"
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/pmset-config.log";
        StandardErrorPath = "/tmp/pmset-config.log";
      };
    }

    # ── MonitorControl ──────────────────────────────────────────────────────
    # Genuinely optional — only hosts with external monitors need per-monitor
    # brightness/config management, parallels host.hardware.audio/bluetooth's
    # real per-host booleans.
    (lib.mkIf config.host.hardware.display {
      environment.systemPackages = [ pkgs.monitorcontrol ];

      system.defaults.CustomUserPreferences."app.monitorcontrol.MonitorControl" = {
        startupAction = 1;
        combinedSlider = true;
      };

      launchd.agents.monitorcontrol.serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-W"
          "${pkgs.monitorcontrol}/Applications/MonitorControl.app"
        ];
        StandardOutPath = "/tmp/monitorcontrol.log";
        StandardErrorPath = "/tmp/monitorcontrol.log";
        KeepAlive = true;
        RunAtLoad = true;
      };
    })
  ];
}
