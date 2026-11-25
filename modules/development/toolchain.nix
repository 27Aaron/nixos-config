{
  config,
  lib,
  pkgs,
  vars,
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

    # 預設 GOPATH 是 ~/go,家目錄頂層會多一個目錄。改到 XDG 資料目錄,
    # 與 pnpm、mise 放在一起。模組快取與 go install 的二進位都在這個目錄裡。
    environment.sessionVariables.GOPATH = "${config.users.users.${vars.username}.home}/.local/share/go";

    # 根目錄是 tmpfs,這些快取沒登記的話每次開機都要重下。建置快取在
    # ~/.cache/go-build,與 GOPATH 分開。pnpm 的 node_modules 以硬連結指回
    # ~/.local/share/pnpm/store。~/.cargo 可能含 credentials.toml。
    preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
      ".cache/go-build"
      ".local/share/go"
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
