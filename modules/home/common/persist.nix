# Bridge for Home Manager tools. They cannot write NixOS-side preservation
# options from their own module, so they report the state they keep here and the
# persistence module splices the entries into `preservation'. Platforms without
# preservation carry the option but never read it.
{ lib, ... }:
let
  entryType =
    kind:
    lib.types.submodule {
      freeformType = lib.types.attrsOf lib.types.anything;

      options.${kind} = lib.mkOption {
        type = lib.types.str;
        description = "Home-relative path of the ${kind} to preserve.";
      };
    };
in
{
  options.persist' = {
    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (entryType "directory"));
      default = [ ];
      description = ''
        Directories to preserve inside the user's home directory. Entries are
        home-relative paths or attribute sets in the shape preservation accepts.
      '';
    };

    files = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (entryType "file"));
      default = [ ];
      description = ''
        Files to preserve inside the user's home directory. Entries are
        home-relative paths or attribute sets in the shape preservation accepts.
      '';
    };
  };
}
