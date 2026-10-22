# 主機

每臺機器一個目錄，依平臺分在 `nixos/` 與 `darwin/` 底下。目錄名就是主機名，
由 `hosts/default.nix` 自動探索，新增主機不必改 flake。

```text
hosts/
├── default.nix        # 探索 nixos/<名稱>/,產生 nixosConfigurations.<名稱>
├── nixos/
│   └── river/         # MECHREVO 無界 14XA 筆電
│       ├── default.nix    # 開關、時區、stateVersion
│       ├── hardware.nix   # 開機載入器、核心、initrd、韌體與週邊
│       ├── storage.nix    # 磁碟佈局、持久化、zram、Btrfs 維護
│       ├── power.nix      # 休眠、睡眠、蓋子與觸控板的恢復修補
│       ├── keyboard.nix   # keyd 鍵位映射
│       └── README.md      # 硬體清單、BIOS 更新與重灌步驟
└── darwin/            # 預留:nix-darwin 主機
```

## 主機目錄放什麼

- `default.nix`：這臺機器開了哪些功能、時區、`stateVersion`，以及匯入同目錄的其他檔案。
- 其他 `.nix` 檔：只屬於這臺機器的設定，依主題拆檔，例如 `hardware.nix`（核心、initrd、韌體）、
  `storage.nix`（磁碟與持久化）。
- `README.md`：硬體規格、PCI ID、BIOS 與重灌步驟等備忘。

能被第二臺機器用到的設定，就不該留在主機目錄，應該做成 `modules/` 底下的模組。

## 新增主機

1. 建立 `hosts/nixos/<名稱>/default.nix`。
2. 需要遠端部署的主機，開啟 `services'.openssh.rootLogin`，之後以
   `just deploy <名稱> root@<位址>` 部署。
3. 執行 `just build <名稱>` 確認能建置。

nix-darwin 主機需要先在 flake 加入 `nix-darwin` 輸入，並在 `hosts/default.nix`
接上 `darwinConfigurations`，加入第一臺 Mac 時一併處理。
