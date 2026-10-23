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
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager.users.${vars.username}.imports = listModules ../../home/darwin;
}
