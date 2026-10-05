{
  programs = {
    # Shell initialization and completion.
    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting

        if command -q uv
          uv generate-shell-completion fish | source
        end

        if command -q uvx
          uvx --generate-shell-completion fish | source
        end
      '';
    };

    # Zsh behavior and completion.
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      initContent = ''
        if command -v uv &>/dev/null; then
          eval "$(uv generate-shell-completion zsh)"
        fi

        if command -v uvx &>/dev/null; then
          eval "$(uvx --generate-shell-completion zsh)"
        fi
      '';
      syntaxHighlighting.enable = true;
    };

    # Prompt styling.
    starship = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        character = {
          success_symbol = "[›](bold green)";
          error_symbol = "[✗](bold red)";
        };
      };
    };

    # Directory listing and navigation.
    eza = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };

    # Command history.
    atuin = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        sync_frequency = 0;
        inline_height = 30;
        history_filter = [
          ''^\s+''
          ''^ls($|(\s+((-([a-zA-Z0-9]|-)+)|"(\.|[^/])[^"]*"|'(\.|[^/])*'|(\.|[^/\s-])[^\s]*))*\s*$)''
          ''^cd($|\s+('[^/][^']*'|"[^/][^"]*"|[^/\s'"][^\s]*))$''
          "/nix/store/.*"
          ''--cookie[=\s]+.+''
        ];
      };
    };
  };

  # Runtime state of the shells and history tools above.
  persist' = {
    directories = [
      ".local/share/fish"
      ".local/share/zoxide"
      {
        directory = ".atuin";
        mode = "0700";
      }
      ".local/share/atuin"
    ];

    files = [ ".zsh_history" ];
  };

  home.shellAliases = {
    cc = "claude --dangerously-skip-permissions";
    cx = "codex --dangerously-bypass-approvals-and-sandbox";
    ll = "eza -lah";
    gs = "git status";
  };
}
