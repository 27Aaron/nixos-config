{ hostName, ... }:
{
  # hostName 即 hosts/darwin/ 下的目錄名;macOS 另有顯示名稱與 SMB 名稱,一併對齊。
  networking = {
    inherit hostName;
    computerName = hostName;
  };
  system.defaults.smb.NetBIOSName = hostName;
}
