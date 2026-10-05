# Contributes the systems this configuration builds to the Flake outputs.
{
  config,
  inputs,
  lib,
  profiles,
  vars,
  ...
}:
let
  configurations = import ../lib/configurations.nix {
    inherit
      lib
      vars
      profiles
      inputs
      ;
    inherit (config) hosts;
  };
in
{
  flake = {
    inherit (configurations) nixosConfigurations darwinConfigurations;
  };
}
