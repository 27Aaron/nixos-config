# Schema for the host data files under hosts/<platform>/<name>/default.nix.
# A host that leaves a required field out, or misspells a profile axis, fails to
# evaluate.
{ lib, ... }:
let
  profileNames = lib.types.listOf lib.types.str;
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

          profiles = {
            nixos = lib.mkOption {
              type = profileNames;
              default = [ ];
              description = "Names of the NixOS profiles this host plays.";
            };

            darwin = lib.mkOption {
              type = profileNames;
              default = [ ];
              description = "Names of the nix-darwin profiles this host plays.";
            };

            home = lib.mkOption {
              type = profileNames;
              default = [ ];
              description = "Names of the Home Manager profile sets this host plays.";
            };
          };

          imports = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [ ];
            description = "Modules that apply to this host only, imported alongside its profiles.";
          };

          settings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Everything else in the host file, applied as a module. Filled in by the inventory, so hosts never set it themselves.";
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
