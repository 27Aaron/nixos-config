# 模組目錄

這裡放所有可重用的 NixOS、nix-darwin 與 Home Manager 模組，按平臺與用途分類。`hosts/<name>/`
只負責開關功能，具體實作都在這裡。

## 目錄結構

```text
modules/
├── default.nix              # 走訪整棵樹，定義 user' 與 hm' 別名
├── base/                    # 預留：NixOS 與 nix-darwin 完全相同的設定
├── darwin/                  # 預留：nix-darwin 系統模組
├── nixos/
│   ├── base/                # 每一臺 NixOS 都可能用到
│   │   ├── core/            #   身分、使用者與管理面（core'.*）
│   │   ├── hardware/        #   機器物理上有什麼（hardware'.*）
│   │   │   └── boot/        #     開機管理與 initrd
│   │   └── services/        #   常駐守護行程（services'.*）
│   ├── desktop/             # 有螢幕的主機（desktop'.*）
│   └── server/              # 預留：無頭主機專用
└── home/                    # Home Manager
    ├── default.nix          # 平臺入口：import ./base 與 ./nixos
    ├── base/
    │   ├── default.nix      # 共用清單：persist' 選項與帳號設定
    │   ├── core/            #   自己不畫介面
    │   ├── tui/             #   接管整個終端（agents/、git/）
    │   └── gui/             #   開一個視窗（agents/、browsers/、editors/、terminal/）
    ├── nixos/               #   只有 NixOS 需要的設定
    └── darwin/              #   預留：只有 macOS 需要的設定
```

各目錄放什麼，看名字就知道；具體有哪些模組，直接 `ls` 該目錄即可。若要了解某個檔案的作用，
檔案開頭的註解說明它為什麼存在。

## 分層規則

三問依序決定位置，先能回答的那個就定案：

1. **哪個平臺？** `base/` 通用，`nixos/` 只給 NixOS，`darwin/` 只給 nix-darwin。
2. **系統還是使用者？** `modules/nixos/` 與 `modules/darwin/` 設系統選項；`modules/home/` 設
   Home Manager 選項。
3. **哪個角色、哪種形態？** 系統模組按角色分 `base`、`desktop`、`server`；Home Manager 模組按
   「程式畫什麼」分 `core`、`tui`、`gui`。

`base/` 的意思是「任何一臺都可能用到」，不是「每一臺都要打開」——開關寫在
`hosts/<name>/default.nix`。

## Home Manager 的三個桶

判斷法只有一句：**程式執行時佔不佔畫面？**

| 桶      | 標準                       | 例子                            |
| ------- | -------------------------- | ------------------------------- |
| `core/` | 完全不佔，印完就退出       | fd、ripgrep、jq、fastfetch、duf |
| `tui/`  | 佔滿終端，需要已存在的終端 | btop、ncdu、lazygit、nvim       |
| `gui/`  | 開一個自己的視窗           | kitty、chrome、zed、nagram      |

終端機模擬器（kitty）屬 `gui/`：它就是那個終端，不依賴別的終端。`ncdu` 與 `duf` 用途幾乎一樣，
但 `duf` 印完就退回、`ncdu` 停在畫面等按鍵，所以分屬兩桶。

## 持久化

根目錄是 tmpfs，重開機即清空，只有登記過的路徑會留下。

- **系統側**用 `preservation'.os.*`、`preservation'.user.*`。
- **Home Manager 側**用 `persist'.directories`、`persist'.files`（相對於家目錄），由
  `nixos/base/hardware/persistence.nix` 併進 `preservation'.user`。

**登記放在擁有該狀態的模組裡**，不要集中到 `persistence.nix`。例如 nix 的快取在 `core/nix.nix`、
鑰匙環在 `home/base/gui/seahorse.nix`。`persistence.nix` 只留沒有專屬模組可歸的系統路徑
（`/var/lib/nixos`、`/var/log` 等）與 GPG 金鑰環。

`~/.cache` 不整體持久化：它幾乎全是可重建內容且成長很快，只有真正需要的快取才逐項登記。

## 新增模組

1. 用上面的三問確定位置，**新建檔案，不要新增頂層目錄**。
2. 系統模組：`options.<namespace>.enable = lib.mkEnableOption "…";`，內容包在
   `config = lib.mkIf cfg.enable { … };`。
3. Home Manager 模組：要加到 `modules/home/base/default.nix` 的 import 清單；NixOS 模組自動載入。
4. 執行 `nix fmt` 與 `just check`。

## Darwin 待辦

`base/`、`darwin/`、`nixos/server/`、`home/darwin/` 目前是空佔位。接 macOS 主機前需要：

- `flake.nix` 加上 `nix-darwin` input 與 `darwinConfigurations` 輸出；
- `modules/default.nix` 改成分平臺走訪，NixOS 走 `base` ＋ `nixos`，darwin 走 `base` ＋ `darwin`；
- darwin 入口 import `home/base` ＋ `home/darwin`，避開 `home/nixos/`。
