# Baseline Home Manager user configuration; the module list itself comes from
# the home profiles the host selects.
{
  host,
  lib,
  osConfig,
  username,
  ...
}:
let
  # State entries are home-relative paths or attribute sets in the shape
  # preservation accepts.
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
  # Home Manager modules report the state they keep through `persist'`, and the
  # persistence module splices the entries into preservation. Declared in the
  # baseline so every module can use it regardless of the selected profiles.
  options.persist' = {
    directories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (entryType "directory"));
      default = [ ];
      description = ''
        Directories to preserve inside the user's home directory.
      '';
    };

    files = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str (entryType "file"));
      default = [ ];
      description = ''
        Files to preserve inside the user's home directory.
      '';
    };
  };

  config = {
    home = {
      inherit username;
      homeDirectory = osConfig.users.users.${username}.home;
      stateVersion = host.homeStateVersion;
      language.collate = "C.UTF-8";
    };

    programs.home-manager.enable = true;

    # The second switch is what skips building the option manual; man.enable
    # alone does not.
    programs.man.enable = false;
    manual.manpages.enable = false;
  };
}
