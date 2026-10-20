# 語言直譯器、建置工具與各語言伺服器。裝在使用者 PATH 上而非編輯器私有
# PATH,所以 Zed 的 lsp path_lookup、VS Code、終端機與腳本都能取用。
#
# 這裡是 nixpkgs 的基底版本;專案要特定版本時由 .envrc 或 mise 決定,direnv
# 會把專案環境疊在前面。因此不要在此追新,那會讓全域環境漂移。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Python;直譯器版本切換交給 uv 或專案的 direnv。
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

    # package.json 依賴的版本懸停。用 Nix 這份,不要編輯器自己下載的。
    package-version-server
  ];
}
