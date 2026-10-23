{
  config,
  inputs,
  lib,
  vars,
  ...
}:
let
  inherit (import ../../../../lib { inherit lib; }) listModules;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.users.${vars.username}.imports = listModules ../../../home/nixos;

  # Home Manager 寫入 dconf 需要系統側支援。
  programs.dconf.enable = true;

  # Home Manager 自己的狀態。
  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".local/state/home-manager"
  ];
}
