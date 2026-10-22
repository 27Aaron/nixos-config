{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop'.lsfg-vk;
in
{
  options.desktop'.lsfg-vk = {
    enable = lib.mkEnableOption "lsfg-vk, the Lossless Scaling frame generation layer for Vulkan";

    dllPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/games/SteamLibrary/steamapps/common/Lossless Scaling/lsfg-vk.dll";
      description = ''
        Path to lsfg-vk.dll in the Lossless Scaling install, exported as
        LSFGVK_DLL_PATH. Null relies on lsfg-vk's own search, which only covers
        Steam's default library under the home directory.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Steam 的 FHS 環境把 /run/opengl-driver/share 加進 XDG_DATA_DIRS,implicit layer
    # 放這裡 Proton 遊戲才找得到;使用者管理器的 XDG_DATA_DIRS 不含系統 profile。
    hardware.graphics.extraPackages = [ pkgs.lsfg-vk ];

    environment = {
      # 只取 CLI:整個套件放進系統 profile 會讓同一個 layer 出現在兩條搜尋路徑。
      systemPackages = [
        pkgs.lsfg-vk-ui
        (pkgs.writeShellScriptBin "lsfg-vk-cli" ''
          exec ${lib.getExe' pkgs.lsfg-vk "lsfg-vk-cli"} "$@"
        '')
      ];

      sessionVariables = lib.mkIf (cfg.dllPath != null) {
        LSFGVK_DLL_PATH = cfg.dllPath;
      };
    };

    # 設定檔由 lsfg-vk-ui 編輯;layer 找不到它時也會自行寫入預設值。
    preservation'.user.directories = [ ".config/lsfg-vk" ];
  };
}
