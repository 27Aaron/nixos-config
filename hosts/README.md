# 主機

每臺機器一個目錄，依平臺分在 `nixos/` 與 `darwin/` 底下。目錄名就是主機名，
由 `hosts/default.nix` 自動探索，新增主機不必改 flake。

```text
hosts/
├── default.nix        # 探索 nixos/<名稱>/,產生 nixosConfigurations.<名稱>
├── nixos/
│   └── river/         # MECHREVO 無界 14X 筆電
└── darwin/            # 預留:nix-darwin 主機
```

## 主機目錄放什麼

- `default.nix`：這臺機器開了哪些功能、時區、`stateVersion`，以及匯入同目錄的其他檔案。
- 其他檔案：只屬於這臺機器的設定，依主題拆檔，例如 `hardware.nix`（韌體、核心、磁碟）。
- `README.md`：硬體規格、BIOS 等備忘。

能被第二臺機器用到的設定，就不該留在主機目錄，應該做成 `modules/` 底下的模組。

## 新增主機

1. 建立 `hosts/nixos/<名稱>/default.nix`。
2. 執行 `just build <名稱>` 確認能建置。

nix-darwin 主機需要先在 flake 加入 `nix-darwin` 輸入，並在 `hosts/default.nix`
接上 `darwinConfigurations`，加入第一臺 Mac 時一併處理。
