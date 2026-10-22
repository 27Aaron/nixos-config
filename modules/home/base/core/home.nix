{
  osConfig,
  vars,
  ...
}:
{
  home = {
    username = vars.username;
    homeDirectory = osConfig.users.users.${vars.username}.home;

    stateVersion = "26.11";
    language.collate = "C.UTF-8";
  };

  programs.home-manager.enable = true;

  # 兩者都關閉才能跳過 option manual 的建置。
  programs.man.enable = false;
  manual.manpages.enable = false;
}
