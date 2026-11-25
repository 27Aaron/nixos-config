{
  config,
  lib,
  ...
}:
let
  cfg = config.development'.project-env;
in
{
  options.development'.project-env.enable = lib.mkEnableOption "project environments with direnv, mise and uv";

  config = lib.mkIf cfg.enable {
    hm'.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global.hide_env_diff = true;
    };

    # mise 只管專案層級的工具版本,全域版本見 toolchain.nix。
    hm'.programs.mise = {
      enable = true;
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

    # 下載快取不在 share 目錄。tmpfs 根目錄不登記的話,重開機就整份重抓。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      ".local/share/direnv"
      ".local/share/mise"
      ".cache/mise"
      ".local/share/uv"
      ".cache/uv"
    ];
  };
}
