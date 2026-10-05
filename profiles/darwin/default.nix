{
  config,
  username,
  ...
}:
{
  imports = [ ../../modules/darwin ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";

    users.${username} = {
      imports = [ ../../modules/home/darwin ];

      home = {
        username = username;
        homeDirectory = config.users.users.${username}.home;
        stateVersion = "26.05";
      };

      programs.home-manager.enable = true;
    };
  };
}
