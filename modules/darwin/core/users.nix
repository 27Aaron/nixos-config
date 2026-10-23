{ vars, ... }:
{
  # nix-darwin 把 system.defaults 等使用者層設定套用到這個帳號。
  system.primaryUser = vars.username;

  # nix-darwin 不會推斷家目錄,未設定時 Home Manager 無法取得路徑。
  user'.home = "/Users/${vars.username}";
}
