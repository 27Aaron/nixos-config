{
  system = "x86_64-linux";

  modules = [
    (
      {
        nixosHardware,
        pkgs,
        username,
        ...
      }:
      {
        imports = [
          nixosHardware.nixosModules.apple-t2
          ../../../../modules/nixos/hardware/disko.nix
          ../../../../modules/nixos/hardware/persistence.nix
          ../../../../modules/nixos/hardware/boot/grub.nix
          ../../../../modules/nixos/hardware/boot/systemd-boot.nix
          ../../../../modules/nixos/hardware/bluetooth.nix
          ../../../../modules/nixos/system/core.nix
          ../../../../modules/nixos/security/firewall.nix
          ../../../../modules/nixos/services/networkmanager.nix
          ../../../../modules/nixos/services/openssh.nix
          ../../../../modules/nixos/services/vnstat.nix
          ./hardware.nix
        ];

        services' = {
          networkmanager.enable = true;
          openssh.enable = true;
          vnstat.enable = true;
        };

        security'.firewall.enable = true;
        hardware'.bluetooth.enable = true;
        hardware'.systemd-boot.enable = true;

        boot.loader.systemd-boot.configurationLimit = 2;
        boot.loader.efi.efiSysMountPoint = "/boot";
        boot.initrd.systemd.enable = true;

        services.openssh.settings = {
          PasswordAuthentication = true;
          KbdInteractiveAuthentication = true;
          PermitRootLogin = "no";
        };

        time.timeZone = "Asia/Shanghai";
        nixpkgs.config.allowUnfree = true;

        hardware.apple-t2.firmware = {
          enable = true;
          version = "sonoma";
        };

        preservation.preserveAt."/persistent".directories = [
          "/etc/nixos"
          "/var/lib/AccountsService"
          {
            directory = "/home/${username}";
            user = username;
            group = "users";
            mode = "0700";
          }
        ];

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        environment.systemPackages = with pkgs; [
          git
          vim
        ];

        system.stateVersion = "26.11";
      }
    )
  ];
}
