{
  description = "Minimal NixOS ISO with Cloud-Init using native NixOS 25.05+ image builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux = {
      proxmox-cloudinit = nixpkgs.lib.nixosSystem {
        modules = [
          # Use modulesPath so Nix dynamically and correctly maps the channel installer path
          ({ pkgs, modulesPath, ... }: {
            imports = [
              "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
            ];

            # Set the host platform explicitly
            nixpkgs.hostPlatform = "x86_64-linux";

            # Core services required for Cloud-Init bootstrapping
            services.cloud-init = {
              enable = true;
              network.enable = false;
              # Explicitly tell cloud-init to look at NoCloud (Proxmox standard)
              settings.datasource_list = [ "NoCloud" "ConfigDrive" ];
            };

            # Enable the QEMU Guest Agent daemon
            services.qemuGuest.enable = true;

            # Override the installation-cd-minimal default to ensure Proxmox MAC/Slot pairing works
            networking.useNetworkd = true;
            networking.usePredictableInterfaceNames = true;

            # Prevent legacy installer scripts from hijacking the interface after boot
            networking.dhcpcd.enable = false;
            networking.useDHCP = false;

            # Enforce strict link configuration to ensure routes are flushed and correctly applied
            systemd.network.networks."99-default-cloudinit" = {
              matchConfig.Name = "eth* ens* enp*";
              networkConfig = {
                LinkLocalAddressing = "no";
              };
              extraConfig = ''
                [Network]
                KeepConfiguration=yes
              '';
            };

            # Unblock boot sequencing as soon as any network interface is online.
            systemd.network.wait-online.anyInterface = true;

            services.openssh = {
              enable = true;
              settings.PermitRootLogin = "yes";
            };

            # Redirect output to serial console for Proxmox UI comfort
            boot.kernelParams = [ "console=ttyS0" ];

            # Core virtualization drivers
            boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" ];

            environment.systemPackages = with pkgs; [ jq git curl ];
          })
        ];
      };

      default = self.packages.x86_64-linux.proxmox-cloudinit.config.system.build.isoImage;
    };
  };
}
