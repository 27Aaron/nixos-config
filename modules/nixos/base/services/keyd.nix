{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services'.keyd;
  ini = pkgs.formats.ini { };
in
{
  options.services'.keyd = {
    enable = lib.mkEnableOption "keyd, a system-wide key remapping daemon";

    keyboards = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          # 鍵盤裝置的個別設定:ids 限定要接管的裝置,
          # settings 對應設定檔中除 [ids] 以外的各個段落。
          options = {
            ids = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "*" ];
              description = "要接管的鍵盤裝置清單,格式如 keyd(1) 所示。";
            };

            settings = lib.mkOption {
              inherit (ini) type;
              default = { };
              description = "每個鍵盤的 keyd 設定,不含 ids 段落。";
            };

            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "附加在檔案末尾的額外設定。";
            };
          };
        }
      );
      default = { };
      description = "一或多個裝置 ID 的設定,以 /etc/keyd/ 下的檔名為鍵。";
    };
  };

  config = lib.mkIf cfg.enable {
    services.keyd = {
      enable = true;
      keyboards = cfg.keyboards;
    };
  };
}
