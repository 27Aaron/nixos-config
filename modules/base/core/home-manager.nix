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
  # Home Manager 本體由 nixos/、darwin/ 各自引入對應平臺的模組。
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";

    # 系統的 specialArgs 不會自動傳入 Home Manager 模組,需顯式轉交。
    extraSpecialArgs = {
      inherit inputs vars;
    };

    # 平臺專屬的使用者模組由 nixos/、darwin/ 各自補上。
    users.${vars.username}.imports = listModules ../../home/base;
  };
}
