# See modules/host/default.nix for the `{ host; module; }` shape/rationale:
# `host` is plain data validated pre-fixpoint by lib/hostSchema.nix and
# mirrored into a real `config.host` option consumed by modules/host/<topic>.
# NOTE: this file must stay a bare `{ host; module; }` attrset, not a
# function — lib/mkConfigurations.nix does a plain `import` on it (no args
# applied), then reads `.host`/`.module` straight off the result.
let
  hddMainID = "ata-ST4000VN006-3CW104_WW609HBC";
  hddCloneID = "ata-ST4000VN006-3CW104_WW609THW";

  nvmeMountOptions = [
    "compress=zstd:3"
    "noatime"
  ];

  hddMountOptions = [
    "compress=zstd:1"
    "noatime"
    "nodev"
    "nosuid"
    "nofail"
  ];
in
{
  host = {
    name = "pc";
    system = "x86_64-linux";
    channel = "unstable";
    type = [
      "desktop"
      "workstation"
      "server"
    ];

    extra.domain = "damidoug.dev";

    hardware = {
      audio = true;
      bluetooth = true;

      boot.efiSupport = true;

      cpu = "amd";
      gpu.amd.legacy = true;

      disk = {
        type = "nvme";

        fileSystem = "btrfs";

        disko.devices.disk = {
          nvme = {
            device = "/dev/nvme0n1";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                esp = {
                  priority = 1;
                  size = "1G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=0077" ];
                  };
                };

                swap = {
                  priority = 2;
                  size = "8G";
                  content = {
                    type = "swap";
                    priority = 10;
                    randomEncryption = true;
                  };
                };

                root = {
                  priority = 3;
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
                        mountOptions = nvmeMountOptions;
                      };
                      "@home" = {
                        mountpoint = "/home";
                        mountOptions = nvmeMountOptions;
                      };
                      "@nix" = {
                        mountpoint = "/nix";
                        mountOptions = nvmeMountOptions;
                      };
                      "@var" = {
                        mountpoint = "/var";
                        mountOptions = nvmeMountOptions;
                      };
                      "@snapshots" = {
                        mountpoint = "/.snapshots";
                        mountOptions = nvmeMountOptions;
                      };
                      "@games" = {
                        mountpoint = "/games";
                        mountOptions = [
                          "nodatacow"
                          "noatime"
                        ];
                      };
                    };
                  };
                };
              };
            };
          };

          hdd = {
            type = "disk";
            device = "/dev/disk/by-id/${hddMainID}";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "data"
                "-d"
                "raid1"
                "-m"
                "raid1"
                "/dev/disk/by-id/${hddCloneID}"
              ];
              subvolumes = {
                "@data" = {
                  mountpoint = "/data";
                  mountOptions = hddMountOptions;
                };
                "@photos" = {
                  mountpoint = "/data/photos";
                  mountOptions = hddMountOptions;
                };
                "@backups" = {
                  mountpoint = "/data/backups";
                  mountOptions = hddMountOptions;
                };
                "@snapshots" = {
                  mountpoint = "/data/.snapshots";
                  mountOptions = hddMountOptions;
                };
              };
            };
          };
        };
      };
    };

    environment = {
      desktop = "gnome";

      locale = {
        timeZone = "Europe/Malta";
        keyboard = "us";
        language = {
          default = "en_US.UTF-8";
          lcTime = "en_IE.UTF-8";
          lcMonetary = "en_IE.UTF-8";
          lcNumeric = "en_IE.UTF-8";
          lcMeasurement = "en_IE.UTF-8";
          lcPaper = "en_IE.UTF-8";
        };
      };

      user = {
        username = "dami";
        fullName = "Douglas Damiano";
        wheelNeedsPassword = false;
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL30CYuB+7IA5hfsYCUadhnyycrhR6+kWCDyDi8DkYk+ dami@mac"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ94IJ+d35YSPBQ4lA9dZkj5Mfug/ylodh6B0EK29GKi dami@pc"
        ];
      };

      # networkmanager backend (networkd.enable defaults false) — interface
      # is only used here by hosts/pc/services/media/jellyfin's firewall
      # rule.
      networking.interface = "eno1";
    };

    tools = {
      agenix = {
        enable = true; # owns hermes/vaultwarden/newt/qbittorrent secrets
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMrxXQxUZkJPyFFa02opA2BOUorjTYnJL4MA3EdBFPxF root@pc";
      };
      homeManager.enable = true;
    };
  };

  module =
    { inputs, ... }:
    {
      imports = [
        inputs.hermes-agent.nixosModules.default
        ./gaming
        ./services
      ];
    };
}
