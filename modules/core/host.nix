{ hostName, ... }:
{
  # hostName 即 hosts/ 下的目錄名,由 hosts/default.nix 傳入。
  networking.hostName = hostName;
}
