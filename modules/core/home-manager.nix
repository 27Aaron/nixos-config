{
  config,
  inputs,
  lib,
  vars,
  ...
}:
let
  inherit (import ../../lib { inherit lib; }) listModules;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";

    # 系統的 specialArgs 不會自動傳入 Home Manager 模組,需顯式轉交。
    extraSpecialArgs = {
      inherit inputs vars;
    };

    # base 一律生效,shared 是主機可以開關的功能。
    users.${vars.username}.imports = listModules ../home/base ++ listModules ../home/shared;
  };

  # Home Manager 寫入 dconf 需要系統側支援。
  programs.dconf.enable = true;

  # Home Manager 自己的狀態。
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".local/state/home-manager"
  ];
}
