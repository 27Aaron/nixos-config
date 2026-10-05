{
  config,
  email,
  fullName,
  lib,
  username,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule [ "user'" ] [ "users" "users" username ])
    (lib.mkAliasOptionModule [ "hm'" ] [ "home-manager" "users" username ])
  ];

  # Home Manager is embedded in the platform system.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = {
      inherit email fullName username;
    };

    users.${username} = {
      imports = [
        ./common/development.nix
        ./common/git.nix
        ./common/kitty.nix
        ./common/persist.nix
        ./common/shell.nix
        ./common/tools.nix
      ];

      home = {
        username = username;
        homeDirectory = config.users.users.${username}.home;
        language.collate = "C.UTF-8";
        stateVersion = "26.05";
      };

      programs.home-manager.enable = true;
      programs.man.enable = false;
      manual.manpages.enable = false;
    };
  };
}
