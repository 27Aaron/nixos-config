# 只有 NixOS 需要的 Home Manager 設定;這裡可以假設 systemd 與 Linux 專屬路徑。
{
  imports = [
    ./caches.nix
    ./magpie.nix
  ];
}
