{
  config,
  lib,
  ...
}:
let
  cfg = config.tui'.lazygit;
in
{
  options.tui'.lazygit.enable = lib.mkEnableOption "lazygit";

  config = lib.mkIf cfg.enable {
    programs.lazygit.enable = true;

    # 最近開啟的倉庫清單。
    persist'.directories = [ ".local/state/lazygit" ];
  };
}
