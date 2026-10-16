{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.core'.sops;

  keyFile = "/var/lib/sops-nix/key.txt";
in
{
  options.core'.sops = {
    enable = lib.mkEnableOption "sops-nix secret decryption";
  };

  config = lib.mkIf cfg.enable {
    sops.age.keyFile = "/persistent${keyFile}";

    # 讓命令列的 sops 與啟用時用同一把私鑰。
    environment = {
      systemPackages = [ pkgs.sops ];
      sessionVariables.SOPS_AGE_KEY_FILE = "/persistent${keyFile}";
    };

    # 根檔案系統是 tmpfs,私鑰必須在開機掛載持久分割區時就位,否則 sops 解不開任何東西。
    preservation'.os.directories = [
      {
        directory = "/var/lib/sops-nix";
        mode = "0700";
        inInitrd = true;
      }
    ];
  };
}
