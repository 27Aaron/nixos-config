{
  config,
  lib,
  vars,
  ...
}:
let
  cfg = config.desktop'."1password";
in
{
  options.desktop'."1password".enable = lib.mkEnableOption "the 1Password desktop app";

  # 不放進 nixpak:瀏覽器整合要靠上游模組的 setgid 包裝程式,系統驗證解鎖
  # 要經過 polkit,兩者在沙箱裡都無法運作。
  config = lib.mkIf cfg.enable {
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ vars.username ];
    };

    # 本機的加密保險庫副本、裝置金鑰與設定。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = ".config/1Password";
        mode = "0700";
      }
    ];
  };
}
