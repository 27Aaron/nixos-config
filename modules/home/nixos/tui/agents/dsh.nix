{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tui'.dsh;

  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
in
{
  options.tui'.dsh.enable = lib.mkEnableOption "the DeepSeek dsh agent";

  config = lib.mkIf cfg.enable {
    home.packages = [ dsh ];

    # 設定、憑證與工作階段都在 DSH_HOME,預設 ~/.dsh。
    persist'.directories = lib.mkIf config.persist'.enable [
      {
        directory = ".dsh";
        mode = "0700";
      }
    ];
  };
}
