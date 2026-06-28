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
              network.enable = true;
            };

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
