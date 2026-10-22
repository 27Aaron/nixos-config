# Home Manager 的 NixOS 整合。使用者模組自動收集自 modules/home/base 與
# modules/home/nixos;nix-darwin 主機改收 base 與 darwin。
{
  inputs,
  lib,
  vars,
  ...
}:
let
  inherit (import ../../../../lib { inherit lib; }) listModules;
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";

    # NixOS 的 specialArgs 不會自動傳入 Home Manager 模組,需顯式轉交。
    extraSpecialArgs = {
      inherit inputs vars;
    };

    users.${vars.username}.imports = listModules ../../../home/base ++ listModules ../../../home/nixos;
  };

  # Home Manager 寫入 dconf 需要系統側支援。
  programs.dconf.enable = true;

  # Home Manager 自己的狀態。
  preservation'.user.directories = [ ".local/state/home-manager" ];
}
