# 模組

所有可重用的設定都在這裡，依用途分目錄。主機只負責開關，實作都在模組裡。

```text
modules/
├── core/        # 每臺主機一律生效,包括 shell 與日常命令列工具
├── hardware/    # 硬體、開機、磁碟與持久化
├── services/    # 背景服務,伺服器也可能用到
├── dev/         # 開發環境、工具鏈與 AI agent,伺服器與桌面都能用
├── desktop/     # 只有接螢幕的主機,包括圖形介面程式
└── server/      # 只有伺服器
```

每個目錄都由 `hosts/default.nix` 以 `lib/default.nix` 的 `listModules` 自動收集，不必手動匯入；子目錄若含 `default.nix`，只載入該檔。

## 放在哪裡

由通用到專用，選第一個符合的位置：

1. 每臺主機都需要，不該能關掉 → `core/`
2. 硬體、開機、磁碟或持久化 → `hardware/`
3. 伺服器也可能用到的服務，例如 SSH、快照、代理 → `services/`
4. 開發用的工具，伺服器上也可能要 → `dev/`
5. 一定要有螢幕才有意義，例如登入畫面、視窗管理器、輸入法、瀏覽器 → `desktop/`
6. 只有伺服器需要 → `server/`

目錄名稱就是選項命名空間，例如 `hardware/` 的模組定義在 `hardware'.*`。底下的子目錄只用來分組，不增加命名空間層級。

## 使用者層的設定

所有模組都是 NixOS 模組。一個程式的系統設定、Home Manager 設定與持久化寫在同一個檔案裡；Home Manager 的部分寫在 `hm'` 底下，它是 `home-manager.users.<使用者>` 的別名：

```nix
config = lib.mkIf cfg.enable {
  hm'.programs.kitty.enable = true;

  preservation'.user.directories = lib.mkIf config.hardware'.persistence.enable [
    ".config/kitty"
  ];
};
```

## 開關

`core/` 的模組一律生效、沒有開關，只放每臺機器都需要的東西。其他模組預設關閉，由主機在 `default.nix` 打開，所以伺服器只會帶入自己開啟的功能。

## 持久化

根目錄是 tmpfs，只有登記過的路徑會留下。系統狀態登記在 `preservation'.os`，使用者狀態登記在 `preservation'.user`，兩者都以 `config.hardware'.persistence.enable` 為條件。`~/.cache` 不整體保留，只登記真正需要的快取。含金鑰、憑證、登入狀態或歷史紀錄的目錄加上 `mode = "0700"`。
