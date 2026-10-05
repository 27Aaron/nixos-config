# Platform-side Home Manager wiring. Which user modules apply is decided by the
# home profiles the host selects.
{
  lib,
  username,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule [ "hm'" ] [ "home-manager" "users" username ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
  };
}
