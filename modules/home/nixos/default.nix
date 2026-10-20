# 只有 NixOS 需要的 Home Manager 設定。
#
# 這裡的檔案可以安全地假設 systemd、Linux 專屬路徑與只在 Linux 打包的套件;
# macOS 主機不會載入這個目錄。
{
  imports = [
    ./magpie.nix
  ];
}
