{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # net.ifnames=0 讓網卡固定叫 eth0;audit 紀錄在這臺 VM 上只是雜訊。
  boot.kernelParams = [
    "audit=0"
    "net.ifnames=0"
  ];

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

  # 安裝時 ESP 只有 256M,保留較少世代以免被核心塞滿。
  boot.loader.systemd-boot.configurationLimit = 4;

  # Proxmox 透過 guest agent 正常關機並回報 IP。
  services.qemuGuest.enable = true;
}
