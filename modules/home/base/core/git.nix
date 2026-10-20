# Git:身分、預設行為,以及配套的命令列工具。
#
# delta 只做差異渲染,輸出後就退回,不接管畫面,所以留在 core。
# 接管整個終端的 lazygit 另有 tui/git/lazygit.nix。
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

    # 差異檢視器;把 pager 設成 delta 由 enableGitIntegration 完成。
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

  # GitHub CLI 與分支清理。
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
