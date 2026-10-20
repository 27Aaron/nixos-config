# lazygit:接管整個終端的 Git 介面。
{
  programs.lazygit.enable = true;

  # 最近開啟的倉庫清單。
  persist'.directories = [ ".local/state/lazygit" ];
}
