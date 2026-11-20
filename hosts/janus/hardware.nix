{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # net.ifnames=0 讓網卡固定叫 eth0;audit 紀錄在這臺 VM 上只是雜訊。
    kernelParams = [
      "audit=0"
      "net.ifnames=0"
    ];
  };

  hardware' = {
    systemd-boot.enable = true;
    disable-balloon.enable = true;

    disko = {
      enable = true;
      device = "/dev/sda";
      tmpfsSize = "512M";
    };
    persistence.enable = true;
  };

  # Proxmox 透過 guest agent 正常關機並回報 IP。
  services.qemuGuest.enable = true;
}
