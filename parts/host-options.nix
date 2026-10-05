# Schema for the host data files under hosts/<platform>/<name>/default.nix.
# A host that leaves a required field out fails to evaluate, naming the option.
{ lib, ... }:
let
  profileList = lib.types.listOf (lib.types.listOf lib.types.deferredModule);
in
{
  options.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Host name; always the directory name.";
          };

          platform = lib.mkOption {
            type = lib.types.enum [
              "nixos"
              "darwin"
            ];
            description = "Platform the host belongs to; always its parent directory.";
          };

          system = lib.mkOption {
            type = lib.types.str;
            description = "System the host evaluates for, for example x86_64-linux.";
          };

          stateVersion = lib.mkOption {
            type = lib.types.either lib.types.str lib.types.int;
            description = "NixOS or nix-darwin state version.";
          };

          homeStateVersion = lib.mkOption {
            type = lib.types.str;
            default = "26.05";
            description = "Home Manager state version.";
          };

          timeZone = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Per-host time zone; the shared value is used when unset.";
          };

          profiles = lib.mkOption {
            type = profileList;
            description = "Platform modules to import, as a list of module lists.";
          };

          home = lib.mkOption {
            type = profileList;
            default = [ ];
            description = "Home Manager user modules, as a list of module lists.";
          };

          modules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [ ];
            description = "Modules that apply to this host only.";
          };

          hardware = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Host facts modules can read through the `host` argument.";
          };
        };
      }
    );
    default = { };
    description = "Every machine in this configuration, keyed by host name.";
  };
}
