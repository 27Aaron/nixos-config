# 開發工具鏈:語言直譯器、建置工具,以及各語言的語言伺服器。
#
# 這些一律裝在使用者的 profile(PATH)上,不綁在單一編輯器裡:
#   - Zed 的 lsp.*.path_lookup 會從 PATH 找到它們;
#   - VS Code 的 Nix 環境選擇器、終端機裡的 go/rustc/cargo 也直接可用;
#   - 任何其他工具(腳本、CLI)都能取用,不必透過編輯器轉一手。
#
# 版本策略:這裡是「開箱即用」的基底版本,固定由 nixpkgs 提供。專案若需要
# 特定版本,由專案的 .envrc / flake.nix 決定,或交由 mise 管理;direnv 會把
# 專案環境疊在前面。因此不要在此追新版本,那會讓全域環境漂移。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Python。直譯器本體;版本切換交給 uv 或專案的 direnv。
    python3
    basedpyright
    ruff

    # Go。
    go
    gopls

    # Rust。
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    # TypeScript / Node。
    nodejs
    typescript
    vtsls

    # package.json 依賴的版本懸停。用 Nix 包的版本,不要編輯器自己下載的那份。
    package-version-server
  ];
}
