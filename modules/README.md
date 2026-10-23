# 模組

所有可重用的設定都在這裡，依「能在哪裡執行」分層。主機只負責開關，實作都在模組裡。

```text
modules/
├── base/      # NixOS 與 nix-darwin 系統層共用
├── nixos/     # 只有 NixOS
├── darwin/    # 只有 nix-darwin,尚無主機載入
└── home/      # Home Manager,使用者層
```

模組由 `lib/default.nix` 自動收集，不必手動匯入。子目錄若含 `default.nix`，只載入該檔。
NixOS 主機載入 `base/`、`nixos/`，以及 `home/base/`、`home/nixos/`；nix-darwin 主機則換成 `darwin/` 與 `home/darwin/`。

## 放在哪裡

由通用到專用，選第一個符合的位置：

1. Mac 和 Linux 的系統層都能用 → `base/`
2. 任何 NixOS 都能用，包括伺服器 → `nixos/base/`
3. 只有接螢幕的 NixOS 才用 → `nixos/desktop/`
4. 只有伺服器才用 → `nixos/server/`
5. 只有 macOS 才用 → `darwin/`
6. 使用者層的程式與設定 → `home/`

## 開關

`core/` 目錄與 `home/base/` 的模組一律生效，沒有開關，只放每臺機器都需要的東西。
其他模組預設關閉，由主機在 `default.nix` 打開，伺服器因此只會帶入自己開啟的功能。
