{
  email,
  fullName,
  pkgs,
  ...
}:
{
  programs = {
    # Git identity and defaults.
    git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          name = fullName;
          email = email;
        };

        fetch.prune = true;
        init.defaultBranch = "main";
        log.date = "iso";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    # Diff viewer and Git terminal UI.
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

  # GitHub CLI and branch cleanup.
  home.packages = [
    pkgs.gh
    pkgs.git-trim
  ];
}
