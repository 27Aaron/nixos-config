{
  config,
  inputs,
  lib,
  vars,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
  };

  hm' = {
    home = {
      username = vars.username;
      homeDirectory = config.users.users.${vars.username}.home;

      stateVersion = vars.homeStateVersion;
      language.collate = "C.UTF-8";
    };

    programs.home-manager.enable = true;

    # 兩者都關閉才能跳過 option manual 的建置。
    programs.man.enable = false;
    manual.manpages.enable = false;
  };

  # Home Manager 寫入 dconf 需要系統側支援。
  programs.dconf.enable = true;

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".local/state/home-manager"
  ];
}
