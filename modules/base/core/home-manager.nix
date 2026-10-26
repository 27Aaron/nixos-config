{
  inputs,
  lib,
  vars,
  ...
}:
let
  inherit (import ../../../lib { inherit lib; }) listModules;
in
{
  # Home Manager 本體由 nixos/ 引入。
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";

    # 系統的 specialArgs 不會自動傳入 Home Manager 模組,需顯式轉交。
    extraSpecialArgs = {
      inherit inputs vars;
    };

    # base 一律生效,shared 是可以開關的功能;NixOS 專屬的使用者模組由 nixos/ 補上。
    users.${vars.username}.imports = listModules ../../home/base ++ listModules ../../home/shared;
  };
}
