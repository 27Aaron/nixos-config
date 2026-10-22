# Home Manager 模組

使用者層的程式與設定。依平臺分成三個目錄，在 `base/` 底下再依程式的介面分類。

```text
home/
├── base/            # Mac 和 Linux 共用
│   ├── home.nix     # 帳號與 Home Manager 本身
│   ├── persist.nix  # persist' 選項
│   ├── cli/         # 命令列工具,不佔用整個終端機(shell、git、工具鏈)
│   ├── tui/         # 佔用整個終端機的介面(lazygit、btop、AI 代理)
│   └── gui/         # 開啟視窗的程式(瀏覽器、編輯器、終端機)
├── nixos/           # 只有 Linux:systemd 使用者服務、Linux 專屬套件
└── darwin/          # 只有 macOS,預留
```

## 載入方式

NixOS 主機由 `nixos/base/core/home-manager.nix` 自動收集 `base/` 與 `nixos/`；
新增檔案不必手動登記。

## 持久化

在 NixOS 上，家目錄同樣位於 tmpfs。模組以 `persist'.directories`、`persist'.files`
回報要保留的路徑（相對於家目錄）。其他平臺不讀取這兩個選項，宣告了也沒有影響。

`~/.cache` 不整體保留，只有真正需要的快取才逐項登記。
