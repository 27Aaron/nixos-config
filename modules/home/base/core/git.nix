# delta 只做差異渲染,不接管畫面所以留在 core;lazygit 在 tui。
{
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
          email = vars.email;
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

  # GitHub CLI 的帳號憑證。
  persist'.directories = [
    {
      directory = ".config/gh";
      mode = "0700";
    }
  ];
}
