{ pkgs, ... }:
{

  programs.fish.enable = true;

  users.users = {
    root.hashedPassword = "!";
    homelab = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      initialPassword = "password";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL30CYuB+7IA5hfsYCUadhnyycrhR6+kWCDyDi8DkYk+ dami@macbook-air"
      ];
    };
  };
}
