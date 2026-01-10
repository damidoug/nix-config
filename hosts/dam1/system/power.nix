{
  power = {
    # macOS already handles freezes well; enable safe auto-restart
    restartAfterFreeze = true;

    sleep = {
      # Power button should sleep (normal macOS behavior)
      allowSleepByPowerButton = true;

      # Laptop should sleep when idle
      computer = 30; # minutes

      # Display should sleep earlier to save battery
      display = 10; # minutes

      # SSD → no need to spin down aggressively
      harddisk = "never";
    };
  };
}
