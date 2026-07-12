let
  mountOptions = [
    "compress=zstd:1"
    "noatime"
  ];
in
{
  host = {
    name = "pangolin";
    system = "x86_64-linux";
    channel = "stable";
    type = [
      "server"
      "qemu"
    ];

    extra.domain = "damidoug.dev";

    hardware = {
      boot.efiSupport = false;

      cpu = "intel";
      gpu.intel = { };

      disk = {
        type = "ssd";
        fileSystem = "btrfs";
        disko.devices.disk.main = {
          device = "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                priority = 1;
                size = "1M";
                type = "EF02";
              };

              esp = {
                priority = 2;
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };

              swap = {
                priority = 3;
                size = "8G";
                content = {
                  type = "swap";
                  priority = 10;
                  randomEncryption = true;
                };
              };

              root = {
                priority = 4;
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f"
                    "-L"
                    "nixos"
                  ];
                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      inherit mountOptions;
                    };
                    "@home" = {
                      mountpoint = "/home";
                      inherit mountOptions;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      inherit mountOptions;
                    };
                    "@var" = {
                      mountpoint = "/var";
                      inherit mountOptions;
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      inherit mountOptions;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    environment = {
      networking = {
        interface = "enp1s0";

        dns = [
          "185.12.64.1"
          "185.12.64.2"
          "2a01:4ff:ff00::add:1"
          "2a01:4ff:ff00::add:2"
        ];
        networkd = {
          enable = true;
          static = {
            addresses = [
              "178.105.229.18/32"
              "2a01:4f8:1c19:24c3::1/64"
            ];
            routes = [
              {
                Gateway = "172.31.1.1";
                GatewayOnLink = true;
              }
              { Gateway = "fe80::1"; }
            ];
          };
        };
      };

      user = {
        username = "dami";
        wheelNeedsPassword = false;
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL30CYuB+7IA5hfsYCUadhnyycrhR6+kWCDyDi8DkYk+ dami@mac"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ94IJ+d35YSPBQ4lA9dZkj5Mfug/ylodh6B0EK29GKi dami@pc"
        ];
      };

      locale = {
        timeZone = "Europe/Malta";
        keyboard = "us";
        language.default = "en_US.UTF-8";
      };
    };

    tools.agenix = {
      enable = true; # owns the pangolin newt secret
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrsPw9DYN0Vh5qhdu7vh6LxS9l1QpqowT90gcB8HjDT root@pangolin";
    };
  };

  module =
    {
      config,
      host,
      ...
    }:
    {
      age.secrets.pangolin.file = ./pangolin.age;

      services.pangolin = {
        enable = true;
        openFirewall = true;
        baseDomain = host.extra.domain;
        letsEncryptEmail = "postmaster@${host.extra.domain}";
        environmentFile = config.age.secrets.pangolin.path;
        settings = {
          app = {
            save_logs = true;
            telemetry.anonymous_usage = false;
          };
          email = {
            smtp_host = "smtp-relay.brevo.com";
            smtp_port = 587;
            no_reply = "no-reply@${host.extra.domain}";
          };
          flags = {
            require_email_verification = true;
            disable_signup_without_invite = true;
            enable_integration_api = false;
          };
        };
      };

      system.activationScripts.pangolin-next = {
        text = ''
          rm -rf /var/lib/pangolin/.next
          cp -r ${config.services.pangolin.package}/share/pangolin/.next /var/lib/pangolin/.next
          chown -R pangolin:fossorial /var/lib/pangolin/.next
          chmod -R u+w /var/lib/pangolin/.next
          touch /var/lib/pangolin/.next/.nix_skip_setup
        '';
        deps = [ "var" ];
      };
    };
}
