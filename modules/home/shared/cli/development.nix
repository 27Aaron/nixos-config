{
  config,
  lib,
  ...
}:
let
  cfg = config.cli.development;
in
{
  options.cli.development.enable = lib.mkEnableOption "project environments with direnv, mise and uv";

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global.hide_env_diff = true;
    };

    # mise 只管專案層級的工具版本,全域版本見 cli/toolchain.nix。
    programs.mise = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
    };

    programs.uv.enable = true;

    programs.fish.interactiveShellInit = ''
      uv generate-shell-completion fish | source
      uvx --generate-shell-completion fish | source
    '';

    programs.zsh.initContent = ''
      eval "$(uv generate-shell-completion zsh)"
      eval "$(uvx --generate-shell-completion zsh)"
    '';

    persist.directories = lib.mkIf config.persist.enable [
      ".local/share/direnv"
      ".local/share/mise"
      ".local/share/uv"

      ".cache/pnpm"
      ".cache/bun"
    ];
  };
}
