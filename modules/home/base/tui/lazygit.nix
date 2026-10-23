{ ... }:
{
  programs.lazygit.enable = true;

  # 最近開啟的倉庫清單。
  persist'.directories = [ ".local/state/lazygit" ];
}
