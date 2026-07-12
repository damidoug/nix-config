# Typed schema + derivation for a host's raw data (hosts/<name>/default.nix's
# `host` attribute). Evaluated by lib/mkConfigurations.nix via
# `lib.evalModules` using a FIXED bootstrap lib (inputs.nixpkgs.lib) — never
# the per-host channel — since this runs *before* a channel/system is even
# chosen for real. This module never touches `pkgs`/`nixpkgs.*`, which is
# what keeps that bootstrap eval safe and independent of the real build.
#
# Real NixOS-style validation instead of hand-rolled asserts: `system`/
# `channel` are `enum`s, so a typo produces a normal Nix type error naming
# the valid values.
#
# Fields are grouped into three themed sub-attrsets (hardware/environment/
# tools) — see modules/README.md's own section on this reorganization for
# the full naming rationale. Only genuine machine-identity fields
# (name/system/channel/type/stateVersion/darwinStateVersion/extra) and the
# derived readOnly fields stay flat on `host.*` directly.
{ lib, config, ... }:
{
  options = {
    name = lib.mkOption { type = lib.types.str; };

    # The "26.05"-style release string — single source of truth for
    # `home.stateVersion` and NixOS's `system.stateVersion` (set automatically
    # in modules/host/default.nix from host.isLinux). darwin's
    # `system.nixpkgsRelease` is `readOnly` there — auto-derived from the
    # nixpkgs input itself, not settable, so it isn't sourced from this field.
    stateVersion = lib.mkOption {
      type = lib.types.str;
      default = "26.05";
    };

    # darwin's *own* `system.stateVersion` is a small, separate integer
    # nix-darwin tracks for its own module compatibility — unrelated to the
    # nixpkgs release string above and not derivable from it, so it needs its
    # own field. Only meaningful on darwin hosts.
    darwinStateVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
    };

    system = lib.mkOption {
      type = lib.types.enum [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    };

    channel = lib.mkOption {
      type = lib.types.enum [
        "unstable"
        "stable"
        "master"
      ];
      default = "unstable";
    };

    # "qemu": this host runs as a QEMU/KVM virtual machine (e.g. a VPS) — no
    # SMART passthrough to its disk, so modules/host/disk/nixos.nix defaults
    # smartd off for it. Orthogonal to desktop/laptop/server/workstation (a
    # host can be e.g. ["server" "qemu"] simultaneously), same list-not-enum
    # reasoning as the rest of this field.
    type = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "desktop"
          "laptop"
          "server"
          "workstation"
          "qemu"
        ]
      );
      default = [ ];
    };

    # Escape hatch for host-specific values that don't warrant a dedicated
    # schema field (e.g. `extra.domain`, read by hosts/pc/services/* and
    # pangolin's own module). Freeform on purpose — unlike every other option
    # here, an unknown key is expected and fine.
    extra = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };

    # ── host.hardware: properties of the physical (or virtual, for
    # `display`'s darwin case) machine. ─────────────────────────────────────
    hardware = {
      cpu = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "intel"
            "amd"
          ]
        );
        default = null;
      };

      # One nullable submodule per vendor — presence (non-null) means "this
      # host has this vendor's GPU", and each vendor's own extra data nests
      # inside it (only meaningful once that vendor is set). At most one may
      # be non-null at a time — enforced by modules/host/gpu/nixos.nix's own
      # assertion, since (unlike the old single-enum shape) the type itself
      # no longer forbids setting more than one.
      gpu = {
        # legacy: pre-GCN4 ("Sea Islands"/"Southern Islands") cards need the
        # legacy si/cik kernel params (see modules/host/gpu/nixos.nix).
        amd = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options.legacy = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };
            }
          );
          default = null;
        };

        # probe: an iGPU newer than what the running kernel's i915 natively
        # recognizes (e.g. Alder Lake at release) needs its PCI device ID
        # force-probed to light up at all. Null means "no force-probe needed".
        intel = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options.probe = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
            }
          );
          default = null;
        };

        # legacy: use the proprietary/closed nvidia kernel module instead of
        # the open one (see modules/host/gpu/nixos.nix's `hardware.nvidia.open`).
        nvidia = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options.legacy = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };
            }
          );
          default = null;
        };
      };

      audio = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      bluetooth = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      # darwin-only (external monitors via MonitorControl,
      # modules/host/power/darwin.nix) — no meaningful equivalent on NixOS
      # hosts, same "just stays false/unset" reasoning as cpu/gpu being null
      # on mac.
      display = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      boot = {
        efiSupport = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        efiMountPoint = lib.mkOption {
          type = lib.types.str;
          default = "/boot";
        };
      };

      disk = {
        type = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "ssd"
              "nvme"
              "hdd"
            ]
          );
          default = null;
        };
        fileSystem = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "ext4"
              "btrfs"
            ]
          );
          default = null;
        };
        disko = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };

        # Directories a service needs to exist before it starts, created via
        # systemd-tmpfiles (modules/host/disk/nixos.nix turns each entry into
        # a "d <path> <mode> <user> <group> - -" rule). A real NixOS option
        # (not just pre-fixpoint host data) — populated both by a host's own
        # `host = {...}` block and, more commonly, by service modules deep in
        # the tree setting `config.host.hardware.disk.folders = [...]`
        # (list-typed options merge across modules, same as
        # environment.systemPackages does), so a service can declare its own
        # directory need next to the rest of its config instead of a
        # hand-written systemd.tmpfiles.rules entry living far away.
        folders = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                path = lib.mkOption { type = lib.types.str; };
                mode = lib.mkOption {
                  type = lib.types.str;
                  default = "0755";
                };
                user = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                };
                group = lib.mkOption {
                  type = lib.types.str;
                  default = "root";
                };
              };
            }
          );
          default = [ ];
        };
      };
    };

    # ── host.environment: how the OS is configured for a human to use it —
    # locale, network identity, the user account, desktop environment
    # choice. Distinct from raw hardware and from tooling. ─────────────────
    environment = {
      desktop = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "gnome"
            "kde"
          ]
        );
        default = null;
      };

      locale = {
        timeZone = lib.mkOption { type = lib.types.str; };

        keyboard = lib.mkOption {
          type = lib.types.str;
          default = "us";
        };

        language = {
          default = lib.mkOption {
            type = lib.types.str;
            default = "en_US.UTF-8";
          };
          lcTime = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          lcMonetary = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          lcNumeric = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          lcMeasurement = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          lcPaper = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      };

      networking = {
        # The one primary interface name a host cares about — used both as
        # the static-networkd match interface
        # (modules/host/networking/nixos.nix) and by
        # hosts/pc/services/media/jellyfin for its firewall interface rule.
        interface = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };

        dns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        networkd = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          static = {
            addresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            routes = lib.mkOption {
              type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
              default = [ ];
            };
          };
        };
      };

      user = {
        username = lib.mkOption { type = lib.types.str; };
        fullName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        wheelNeedsPassword = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        sshKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
    };

    # ── host.tools: software infrastructure this host opts into, each with
    # its own enable + settings. ────────────────────────────────────────────
    tools = {
      # home-manager is auto-injected (nixosModules/darwinModules) when
      # `enable` is true — see modules/host/default.nix and
      # lib/mkConfigurations.nix. `channel` picks which home-manager
      # *release* to pair it with — null means "automatic": follow `channel`
      # above (stable -> home-manager-stable, unstable/master ->
      # home-manager's master branch). Unlike nix-darwin, home-manager-stable
      # is only *recommended* for a stable host, not required, so a host can
      # set this explicitly to override the automatic pairing (see
      # modules/README.md).
      homeManager = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        channel = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "unstable"
              "stable"
              "master"
            ]
          );
          default = null;
        };
      };

      # host.tools.agenix has no modules/host/agenix/ topic module — its only
      # consumers are lib/mkConfigurations.nix (gates both the `age.secrets`
      # module and the CLI package on this one flag) and the repo-root
      # secrets.nix (scopes which .age files this host's key can decrypt).
      # `enable` defaults false — a host that neither owns secrets nor edits
      # them locally needs neither the module nor the CLI. Any host that
      # turns this on is asserted (lib/mkConfigurations.nix's `assertHost`)
      # to also set `publicKey`, since a host with the module but no key
      # could never be scoped as a decrypt recipient by secrets.nix anyway.
      agenix = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        # This host's own root SSH public key — normally its
        # /etc/ssh/ssh_host_ed25519_key.pub (age.identityPaths' default
        # identity), set here so secrets.nix can scope every
        # hosts/<name>/** .age file to this host alone instead of every host
        # in the repo. A single string, not a list — only the host's own
        # root key is ever needed.
        publicKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };
    };

    # ── derived, not set by a host — see `config` below ──────────────────
    arch = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
    };
    os = lib.mkOption {
      type = lib.types.enum [
        "linux"
        "darwin"
      ];
      readOnly = true;
    };
    isLinux = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    isDarwin = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    isDesktop = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    isServer = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    isWorkstation = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
    isQemu = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
    };
  };

  config = {
    arch = builtins.elemAt (lib.splitString "-" config.system) 0;
    os = builtins.elemAt (lib.splitString "-" config.system) 1;
    isLinux = config.os == "linux";
    isDarwin = config.os == "darwin";
    isDesktop = builtins.elem "desktop" config.type;
    isLaptop = builtins.elem "laptop" config.type;
    isServer = builtins.elem "server" config.type;
    isWorkstation = builtins.elem "workstation" config.type;
    isQemu = builtins.elem "qemu" config.type;
  };
}
