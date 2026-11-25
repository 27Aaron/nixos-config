{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development'.toolchain;
in
{
  options.development'.toolchain.enable = lib.mkEnableOption "language toolchains and language servers";

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
      pnpm
      typescript
      vtsls

      # package.json 相依套件的版本提示,避免編輯器自行下載。
      package-version-server
    ];

    # 根目錄是 tmpfs,這些快取沒登記的話每次開機都要重下。Go 模組在
    # ~/go/pkg/mod,建置快取在 ~/.cache/go-build。pnpm 的 node_modules 以
    # 硬連結指回 ~/.local/share/pnpm/store。~/.cargo 可能含 credentials.toml。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      ".cache/go-build"
      "go/pkg/mod"
      {
        directory = ".cargo";
        mode = "0700";
      }
      ".cache/pnpm"
      ".local/share/pnpm"
      ".local/state/pnpm"
    ];
  };
}
