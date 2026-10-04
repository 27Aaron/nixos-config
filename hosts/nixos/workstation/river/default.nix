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
            directory = "/home/${username}";
            user = username;
            group = "users";
            mode = "0700";
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
