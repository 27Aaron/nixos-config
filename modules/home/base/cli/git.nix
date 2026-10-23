{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
{
  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          name = vars.fullName;
          email = "85681241+27Aaron@users.noreply.github.com";
        };

        fetch.prune = true;
        init.defaultBranch = "main";
        log.date = "iso";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    # pager 由 enableGitIntegration 設成 delta。
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        diff-so-fancy = true;
        line-numbers = true;
        true-color = "always";
      };
    };
  };

  home.packages = [
    pkgs.gh
    pkgs.git-trim
  ];

  home.shellAliases.gs = "git status";

  # GitHub CLI 的帳號憑證。
  persist.directories = lib.mkIf config.persist.enable [
    {
      directory = ".config/gh";
      mode = "0700";
    }
  ];
}
