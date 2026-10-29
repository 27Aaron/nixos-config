{
  config,
  lib,
  ...
}:
let
  cfg = config.dev'.project-env;
in
{
  options.dev'.project-env.enable = lib.mkEnableOption "project environments with direnv, mise and uv";

  config = lib.mkIf cfg.enable {
    hm'.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global.hide_env_diff = true;
    };

    # mise 只管專案層級的工具版本,全域版本見 toolchain.nix。
    hm'.programs.mise = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };

    hm'.programs.uv.enable = true;

    hm'.programs.fish.interactiveShellInit = ''
      uv generate-shell-completion fish | source
      uvx --generate-shell-completion fish | source
    '';

    hm'.programs.zsh.initContent = ''
      eval "$(uv generate-shell-completion zsh)"
      eval "$(uvx --generate-shell-completion zsh)"
    '';

    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      ".local/share/direnv"
      ".local/share/mise"
      ".local/share/uv"

      ".cache/pnpm"
      ".cache/bun"
    ];
  };
}
