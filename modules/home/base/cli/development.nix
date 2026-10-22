{
  config,
  lib,
  ...
}:
let
  cfg = config.cli'.development;
in
{
  options.cli'.development.enable = lib.mkEnableOption "project environments with direnv, mise and uv";

  config = lib.mkIf cfg.enable {
    # 用 direnv + nix-direnv 載入專案環境。
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # 載入 .envrc 時不列出環境變數差異。
      config.global.hide_env_diff = true;
    };

    # mise 只管專案層級的工具版本,全域版本見 cli/toolchain.nix。
    programs.mise = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };

    programs.uv.enable = true;

    # .envrc 允許清單、mise 工具鏈、uv 直譯器。
    persist'.directories = [
      ".local/share/direnv"
      ".local/share/mise"
      ".local/share/uv"
    ];
  };
}
