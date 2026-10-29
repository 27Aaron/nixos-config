# 模組

所有可重用的設定都在這裡，依用途分目錄。主機只負責開關，實作都在模組裡。

```text
modules/
├── core/        # 每臺主機一律生效
├── hardware/    # 硬體、開機、磁碟與持久化
├── services/    # 背景服務,伺服器也可能用到
├── desktop/     # 只有接螢幕的主機
├── server/      # 只有伺服器
└── home/        # Home Manager,使用者層
```

除了 `home/`，每個目錄都是系統模組，由 `hosts/default.nix` 以 `lib/default.nix` 的 `listModules` 自動收集，不必手動匯入；子目錄若含 `default.nix`，只載入該檔。`home/` 由 `core/home-manager.nix` 載入。

## 放在哪裡

由通用到專用，選第一個符合的位置：

1. 每臺主機都需要，不該能關掉 → `core/`
2. 硬體、開機、磁碟或持久化 → `hardware/`
3. 伺服器也可能用到的服務，例如 SSH、快照、代理 → `services/`
4. 一定要有螢幕才有意義，例如登入畫面、視窗管理器、輸入法 → `desktop/`
5. 只有伺服器需要 → `server/`
6. 使用者層的程式與設定 → `home/`

目錄名稱就是選項命名空間，例如 `hardware/` 的模組定義在 `hardware'.*`。底下的子目錄只用來分組，不增加命名空間層級。

## 開關

`core/` 與 `home/base/` 的模組一律生效、沒有開關，只放每臺機器都需要的東西。其他模組預設關閉，由主機在 `default.nix` 打開，所以伺服器只會帶入自己開啟的功能。

## 持久化

根目錄是 tmpfs，只有登記過的路徑會留下。系統狀態登記在 `preservation'.os`，使用者狀態登記在 `preservation'.user`。含金鑰、憑證或私人資料的目錄加上 `mode = "0700"`。
