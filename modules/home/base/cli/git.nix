# delta 只渲染差異輸出,屬於 core;lazygit 在 tui。
{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  cfg = config.cli'.git;
in
{
  options.cli'.git.enable = lib.mkEnableOption "Git with delta and the GitHub CLI";

  config = lib.mkIf cfg.enable {
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
  };
}
