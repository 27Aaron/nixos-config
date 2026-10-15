{
  pkgs,
  vars,
  ...
}:
{
  programs = {
    # Git 身分與預設行為。
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

    # 差異檢視器與 Git 終端機介面。
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        diff-so-fancy = true;
        line-numbers = true;
        true-color = "always";
      };
    };

    lazygit.enable = true;
  };

  # GitHub CLI 與分支清理。
  home.packages = [
    pkgs.gh
    pkgs.git-trim
  ];

  # 執行時狀態:GitHub CLI 的帳號,以及 lazygit 的最近倉庫。
  persist'.directories = [
    {
      directory = ".config/gh";
      mode = "0700";
    }
    ".local/state/lazygit"
  ];
}
