# 全域語言工具鏈與語言伺服器,裝在使用者 PATH 上,供編輯器、終端機與腳本共用。
# 這裡只放 nixpkgs 的基底版本;專案需要特定版本時由 direnv 或 mise 覆蓋。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
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
}
