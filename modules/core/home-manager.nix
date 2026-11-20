{
  config,
  inputs,
  lib,
  vars,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
  };

  hm' = {
    home = {
      username = vars.username;
      homeDirectory = config.users.users.${vars.username}.home;

      stateVersion = vars.homeStateVersion;
      language.collate = "C.UTF-8";
    };

    programs.home-manager.enable = true;

    programs.man.enable = false;
    manual.manpages.enable = false;
  };

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".local/state/home-manager"
  ];
}
