{
  self,
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.harryConfiguration = moduleWithSystem (
    { self', ... }:
    {
      config,
      pkgs,
      lib,
      ...
    }:

    {
      imports = with self.nixosModules; [
        inputs.nixos-hardware.nixosModules.microsoft-surface-common
        harryHardware
        desktop
        base
        gaming
        devel
        wslMount
      ];

      networking.hostName = "harry";

      # Slow and thermally limited, so builds go to desktop when it's reachable
      # (nix falls back to building locally when it isn't). By IP because the
      # LAN has no DNS worth trusting -- keep the lease reserved on the router.
      nix = {
        distributedBuilds = true;
        buildMachines = [
          {
            hostName = "172.16.58.56";
            sshUser = "nixremote";
            sshKey = config.sops.secrets."nixremote-ssh-private-key".path;
            systems = [ "x86_64-linux" ];
            protocol = "ssh-ng";
            maxJobs = 8;
            # Above 1 makes nix prefer the builder over this host's own slot.
            speedFactor = 4;
            supportedFeatures = [
              "nixos-test"
              "benchmark"
              "big-parallel"
              "kvm"
            ];
          }
        ];
        # Let the builder fetch substitutes rather than routing them via here.
        settings.builders-use-substitutes = true;
      };

      sops.secrets."nixremote-ssh-private-key" = { };

      # The daemon connects non-interactively, so an unknown host key has to fail
      # rather than prompt.
      programs.ssh.knownHosts."172.16.58.56".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVZzvjJ7CEXey/SJo2bbkzZsZ9JDxHLJYeTP/DXYaq+";

      # The release this machine was installed at; never bumped.
      system.stateVersion = "26.05";

      programs.niri.package = self'.packages.myNiri.wrap {
        settings.outputs = lib.mkForce {
          "eDP-1" = {
            scale = 1.75;
            position = _: {
              props = {
                x = 103;
                y = 1080;
              };
            };

          };
          "DP-1" = {
            scale = 1;
            position = _: {
              props = {
                x = 0;
                y = 0;
              };
            };
          };
        };
      };

      # The IPU3 camera's lens-focus VCM driver isn't autoloaded.
      boot.kernelModules = [ "dw9719" ];

      # The Surface kernel (6.19) emits an ABI name current rustc rejects.
      # Remove when its target generator gains the upstream softfloat fix.
      boot.kernelPatches = [
        {
          name = "rust-softfloat-abi";
          patch = pkgs.writeText "linux-rust-softfloat-abi.patch" ''
            --- a/scripts/generate_rust_target.rs
            +++ b/scripts/generate_rust_target.rs
            @@ -197,7 +197,7 @@
                 } else if cfg.has("X86_64") {
                     ts.push("arch", "x86_64");
                     if cfg.rustc_version_atleast(1, 86, 0) {
            -            ts.push("rustc-abi", "x86-softfloat");
            +            ts.push("rustc-abi", "softfloat");
                     }
                     ts.push(
                         "data-layout",
          '';
        }
      ];

      swapDevices = [
        {
          device = "/var/lib/swapfile";
          size = 8 * 1024;
        }
      ];

      services.thermald.enable = true;

      # Duplicate playback to the two Bluetooth headphones when both are connected.
      services.pipewire.extraConfig.pipewire."90-dual-bluetooth-headphones" = {
        "context.modules" = [
          {
            name = "libpipewire-module-combine-stream";
            args = {
              "combine.mode" = "sink";
              "node.name" = "dual_bluetooth_headphones";
              "node.description" = "Both Bluetooth headphones";
              "combine.latency-compensate" = true;
              "combine.props" = {
                "audio.position" = [
                  "FL"
                  "FR"
                ];
              };
              "stream.rules" = [
                {
                  matches = [
                    {
                      "media.class" = "Audio/Sink";
                      "node.name" = "~bluez_output\\.AC_80_0A_CB_8C_32\\..*";
                    }
                    {
                      "media.class" = "Audio/Sink";
                      "node.name" = "~bluez_output\\.BC_3E_0B_21_5A_3A\\..*";
                    }
                  ];
                  actions."create-stream" = { };
                }
              ];
            };
          }
        ];
      };

      # Battery-only, so not in the shared desktop module.
      services.power-profiles-daemon.enable = true;

      environment.systemPackages = with pkgs; [
        libcamera
        v4l-utils
      ];

      wslMount.vhdxPath = "/mnt/c/Users/janni/AppData/Local/Packages/46932SUSE.openSUSETumbleweed_022rs5jcyhyac/LocalState/ext4.vhdx";

      sops.secrets."harry-wireguard-private-key" = { };
      sops.secrets."harry-wireguard-psk" = { };

      networking.wg-quick.interfaces.fritzbox = {
        address = [
          "192.168.178.204/24"
          "fd00::204/64"
        ];
        dns = [
          "192.168.178.36"
          "192.168.178.1"
          "fd00::ec"
          "fd00::4a5d:35ff:fea4:ff42"
          "fritz.box"
        ];
        privateKeyFile = config.sops.secrets."harry-wireguard-private-key".path;
        mtu = 1280;
        peers = [
          {
            publicKey = "nKFJElLkeRgS0WqYt4TONILr5qFJia1+MA+wxyJMY0E=";
            presharedKeyFile = config.sops.secrets."harry-wireguard-psk".path;
            allowedIPs = [
              "192.168.178.0/24"
              "fd00::/64"
            ];
            endpoint = "vpn.jhiller.me:55974";
            persistentKeepalive = 25;
          }
        ];
      };

      # wg-quick resolves the endpoint hostname once, when the unit starts, and
      # NetworkManager reaches network-online.target before /etc/resolv.conf has
      # a usable nameserver -- so at boot this fails instantly with "Name or
      # service not known" and, being a oneshot, stays down. Retry until DNS
      # answers; no start limit, so it is never permanently down.
      systemd.services.wg-quick-fritzbox = {
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
    }
  );
}
