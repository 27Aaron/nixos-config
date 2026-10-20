# 模組目錄

這裡放所有可重用的 NixOS、nix-darwin 與 Home Manager 模組，按平臺與用途分類。
`hosts/<name>/` 只負責開關功能，具體實作都在這裡。

## 目錄結構

```text
modules/
├── default.nix              # 走訪整棵樹，定義 user' 與 hm' 別名
├── base/                    # 預留：NixOS 與 nix-darwin 完全相同的設定
├── darwin/                  # 預留：nix-darwin 系統模組
├── nixos/
│   ├── base/                # 每一臺 NixOS 都可能用到
│   │   ├── core/            # 身分、使用者與管理面（core'.*）
│   │   ├── hardware/        # 機器物理上有什麼（hardware'.*）
│   │   │   └── boot/        # 開機管理與 initrd
│   │   └── services/        # 常駐守護行程（services'.*）
│   ├── desktop/             # 有螢幕的主機（desktop'.*）
│   └── server/              # 預留：無頭主機專用
└── home/                    # Home Manager
    ├── default.nix          # 平臺入口：import ./base 與 ./nixos
    ├── base/
    │   ├── default.nix      # 共用清單：persist' 選項與帳號設定
    │   ├── core/            # 自己不畫介面
    │   ├── tui/             # 接管整個終端（agents/、git/）
    │   └── gui/             # 開一個視窗（agents 等子目錄）
    ├── nixos/               # 只有 NixOS 需要的設定
    └── darwin/              # 預留：只有 macOS 需要的設定
```

## 持久化

根目錄是 tmpfs，重開機即清空，只有登記過的路徑會留下。

- **系統側**用 `preservation'.os.*`、`preservation'.user.*`。
- **Home Manager 側**用 `persist'.directories`、`persist'.files`（相對於家目錄），
  由 `nixos/base/hardware/persistence.nix` 併進 `preservation'.user`。

`~/.cache` 不整體持久化：它幾乎全是可重建內容且成長很快，只有真正需要的快取
才逐項登記。
