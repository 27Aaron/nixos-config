{
  system = "x86_64-linux";

  modules = [
    (
      {
        config,
        nixosHardware,
        pkgs,
        username,
        ...
      }:
      {
        imports = [
          nixosHardware.nixosModules.apple-t2
          ../../../../profiles/nixos/desktop.nix
          ../../../../modules/nixos/hardware/disko.nix
          ../../../../modules/nixos/hardware/persistence.nix
          ../../../../modules/nixos/hardware/boot/grub.nix
          ../../../../modules/nixos/hardware/boot/systemd-boot.nix
          ./hardware.nix
        ];

        time.timeZone = "Asia/Tokyo";

        preservation.preserveAt."/persistent".directories = [
          {
            # preservation auto-generates a matching rule for this path from
            # users.users.<name>.{homeMode,group}; reference the same values
            # here so the two definitions don't conflict.
            directory = "/home/${username}";
            user = username;
            group = config.users.users.${username}.group;
            mode = config.users.users.${username}.homeMode;
          }
        ];

        environment.systemPackages = with pkgs; [
          git
          vim
        ];

        system.stateVersion = "26.05";
      }
    )
  ];
}
