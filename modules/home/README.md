# Home Manager 模組

使用者層的程式與設定。

```text
home/
├── base/      # 一律生效、沒有開關,伺服器、桌面、macOS 都能用:core/、cli/、tui/、gui/
├── shared/    # 主機可以選擇開關,NixOS 與 macOS 都能用:cli/、tui/、gui/
├── nixos/     # 主機可以選擇開關,只有 NixOS:cli/、tui/、gui/
└── darwin/    # 只有 macOS:core/、gui/
```

## 放在哪裡

1. 每臺主機都需要，而且在 macOS 上也能用 → `base/`。只放簡單、通用的東西，例如 shell、Git、
   日常命令列工具。
2. 主機要能選擇開不開，而且在 macOS 上也能用 → `shared/`，例如開發環境、AI agent。
3. 主機要能選擇開不開，只在 NixOS 上用 → `nixos/`，例如 Linux 才有的圖形介面程式。
4. 只有 macOS 才用 → `darwin/`。`darwin/core/` 一律生效，其餘預設關閉；只管理 Homebrew cask 設定檔的模組，預設跟著
cask 清單啟用。

底下依介面分類：不佔用終端機的放 `cli/`，佔用整個終端機的放 `tui/`，開啟視窗的放 `gui/`。
無法分類的放 `base/core/`。`base/` 的四個目錄都要保留，沒有內容時以 `.gitkeep` 佔位。

## 持久化

模組以 `persist.directories`、`persist.files` 回報要保留的家目錄路徑，由 NixOS 的持久化模組併入。
`~/.cache` 不整體保留，只登記真正需要的快取。含憑證、登入狀態或歷史紀錄的目錄加上 `mode = "0700"`。
