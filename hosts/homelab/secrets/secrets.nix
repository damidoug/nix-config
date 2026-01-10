let
  dami = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL30CYuB+7IA5hfsYCUadhnyycrhR6+kWCDyDi8DkYk+ dami@macbook-air";
  homelab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgVNsHBJlGHhm9/rpbYiXeQHtCAc3Gz1HrW1AiI5b0u root@homelab";
in
{
  "vaultwarden.age".publicKeys = [
    dami
    homelab
  ];

  "cloudflared.age".publicKeys = [
    dami
    homelab
  ];

  "beszel.age".publicKeys = [
    dami
    homelab
  ];
}
