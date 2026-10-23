{ config, lib, ... }:
{
  programs.lazygit.enable = true;

  # 最近開啟的倉庫清單。
  persist'.directories = lib.mkIf config.persist'.enable [ ".local/state/lazygit" ];
}
