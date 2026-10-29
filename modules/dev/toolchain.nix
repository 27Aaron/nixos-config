{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dev'.toolchain;
in
{
  options.dev'.toolchain.enable = lib.mkEnableOption "language toolchains and language servers";

  config = lib.mkIf cfg.enable {
    # 裝在使用者 PATH 上,供編輯器、終端機與腳本共用。這裡只放 nixpkgs 的
    # 基底版本;專案需要特定版本時由 direnv 或 mise 覆蓋。
    hm'.home.packages = with pkgs; [
      # nixfmt-rs 提供 nixfmt 指令,Zed 的格式化設定用的就是它。
      nixd
      nixfmt-rs
      deadnix

      # Python 版本切換交給 uv 或 direnv。
      python3
      basedpyright
      ruff

      go
      gopls

      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer

      nodejs
      typescript
      vtsls

      # package.json 相依套件的版本提示,避免編輯器自行下載。
      package-version-server
    ];

    # Go 的建置快取;保留可免去重開機後重新編譯。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [ ".cache/go-build" ];
  };
}
