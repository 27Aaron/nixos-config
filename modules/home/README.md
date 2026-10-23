# Home Manager 模組

使用者層的程式與設定。

```text
home/
├── base/      # 一律生效、沒有開關,伺服器、桌面、macOS 都能用:core/、cli/、tui/、gui/
├── nixos/     # 主機可以選擇開關的功能:cli/、tui/、gui/
└── darwin/    # 只有 macOS,預留
```

## 放在哪裡

1. 每臺主機都需要，而且在 macOS 上也能用 → `base/`。只放簡單、通用的東西，例如 shell、Git、
   日常命令列工具。
2. 主機要能選擇開不開的功能 → `nixos/`，例如開發環境、AI agent、圖形介面程式。
3. 只有 macOS 才用 → `darwin/`。

底下依介面分類：不佔用終端機的放 `cli/`，佔用整個終端機的放 `tui/`，開啟視窗的放 `gui/`。
無法分類的放 `base/core/`。`base/` 的四個目錄都要保留，沒有內容時以 `.gitkeep` 佔位。

## 持久化

模組以 `persist.directories`、`persist.files` 回報要保留的家目錄路徑，由 NixOS 的持久化模組併入。
`~/.cache` 不整體保留，只登記真正需要的快取。含憑證、登入狀態或歷史紀錄的目錄加上 `mode = "0700"`。
