{
  config,
  ...
}:
{
  homebrew = {
    enable = true;

    enableFishIntegration = config.programs.fish.enable;
    enableZshIntegration = config.programs.zsh.enable;

    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
      upgrade = false;
    };

    taps = [ ];

    brews = [
      "ffmpeg"
      "mole"
      "tokei"
    ];

    masApps = {
      "Bob" = 1630034110;
      "WPS" = 1443749478;
    };

    casks = [
      # AI
      "cc-switch"
      "chatgpt"
      "claude-code"
      "codex"
      "codexbar"
      "grok-build"
      "zcode"

      # Browsers
      "firefox"
      "google-chrome"

      # Communication
      "feishu"
      "telegram"
      "wechat"

      # Development
      "orbstack"
      "visual-studio-code"
      "zed"

      # Fonts
      "font-hack-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "font-lxgw-wenkai"
      "font-maple-mono-nf-cn"
      "font-material-icons"

      # Hardware
      "macs-fan-control"
      "monitorcontrol"

      # Input & keyboard
      "input-source-pro"
      "karabiner-elements"

      # Media
      "iina"
      "neteasemusic"
      "obs"
      "plex"

      # Menu bar
      "jordanbaird-ice@beta"
      "stats"

      # Network
      "surge"

      # Productivity
      "obsidian"
      "qspace-pro"
      "raycast"

      # Remote access
      "termius"
      "uuremote"

      # Terminal
      "ghostty"
      "kitty"
    ];
  };
}
