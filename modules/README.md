# 模組

所有可重用的設定都在這裡，依「能在哪裡執行」分層。主機只負責開關，實作都在模組裡。

```text
modules/
├── base/        # NixOS 與 nix-darwin 系統層共用
├── nixos/       # 只有 NixOS(桌面、伺服器、路由器)
├── darwin/      # 只有 nix-darwin(macOS)
└── home/        # Home Manager,使用者層
```

各目錄的細節見其中的 `README.md`。

## 載入方式

模組由 `lib/default.nix` 的 `listModules` 自動收集，不需要手動加進匯入清單：

- 一般 `.nix` 檔直接載入。
- 子目錄若含 `default.nix`，只載入該檔，由它自行匯入其餘檔案。
- 子目錄若不含 `default.nix`，繼續往下收集。

各平臺收集的範圍：

| 主機 | 系統層 | Home Manager |
|---|---|---|
| NixOS | `base/` + `nixos/` | `home/base/` + `home/nixos/` |
| nix-darwin | `base/` + `darwin/` | `home/base/` + `home/darwin/` |

## 放在哪裡

由通用到專用，選第一個符合的位置：

1. Mac 和 Linux 的系統層都能用 → `base/`
2. 任何 NixOS 都能用，包括伺服器 → `nixos/base/`
3. 只有接螢幕的 NixOS 才用 → `nixos/desktop/`
4. 只有伺服器才用 → `nixos/server/`
5. 只有 macOS 才用 → `darwin/`
6. 使用者層的程式與設定 → `home/`，見 `home/README.md`

## 開關

- **`core/` 目錄裡的模組一律生效，沒有開關**：只放每臺機器都必須有的東西，
  例如帳號、nix 設定、防火牆。需要讓主機微調的數值放在 `core'.*`，
  例如 `core'.logging.journalMaxUse`，但不提供 `enable`。
- **其他模組一律預設關閉**，要在主機的 `default.nix` 寫 `enable = true` 才會生效。
  伺服器因此只會帶入自己開啟的功能。

## 撰寫慣例

- 一個檔案只負責一個程式或一個面向；安裝、設定與持久化放在同一個檔案。
- 設定多到一個檔案放不下時，改成資料夾，以 `default.nix` 為入口。
- 同類檔案有兩個以上才建子目錄。
- 選項放在依目錄命名的命名空間，例如 `nixos/base/services/` → `services'.*`。

## 別名

`base/core/aliases.nix` 定義兩個別名，指向主要使用者：

- `user'.*` → `users.users.<使用者>`
- `hm'.*` → `home-manager.users.<使用者>`
