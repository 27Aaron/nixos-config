{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware'.lanzaboote;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.hardware'.lanzaboote = {
    enable = lib.mkEnableOption ''
      Secure Boot through lanzaboote, which installs signed systemd-boot stubs and
      replaces hardware'.systemd-boot. Keys are created and enrolled by hand with sbctl;
      see the Secure Boot section of SECURITY.md
    '';
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.boot.loader.systemd-boot.enable;
        message = "hardware'.lanzaboote replaces systemd-boot; disable hardware'.systemd-boot.";
      }
    ];

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = lib.mkDefault 8;
      # 預設沿用 systemd-boot 的選項,而上游的 editor 預設是開啟。
      settings = {
        editor = lib.mkDefault false;
        console-mode = lib.mkDefault "max";
      };
    };

    environment.systemPackages = [ pkgs.sbctl ];

    # 根目錄是 tmpfs,金鑰不保留的話下次 rebuild 就無法簽章;私鑰只限 root 讀取。
    preservation'.os.directories = lib.mkIf config.hardware'.persistence.enable [
      {
        directory = "/var/lib/sbctl";
        mode = "0700";
      }
    ];
  };
}
