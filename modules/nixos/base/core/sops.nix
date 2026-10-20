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

    environment = {
      systemPackages = [ pkgs.sops ];
      sessionVariables.SOPS_AGE_KEY_FILE = "/persistent${keyFile}";
    };

    # 根目錄是 tmpfs,私鑰得在 initrd 掛載持久分割區時就位,否則誰都解不開。
    preservation'.os.directories = [
      {
        directory = "/var/lib/sops-nix";
        mode = "0700";
        inInitrd = true;
      }
    ];
  };
}
