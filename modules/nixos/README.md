# NixOS 模組

只有 NixOS 才載入的模組。依用途分成三類，伺服器只開它需要的功能。

```text
nixos/
├── base/                    # 任何 NixOS 都可能用到,包括伺服器與路由器
│   ├── core/                # 一律生效:帳號與 sops、主機名、語系、防火牆、日誌、ssh 客戶端修正、nh、HM 整合
│   ├── hardware/            # 機器上有什麼硬體:GPU、藍牙、亮度、YubiKey、磁碟、持久化(hardware'.*)
│   │   └── boot/            # 開機管理
│   └── services/            # 常駐服務:SSH、dae、快照、監控(services'.*)
├── desktop/                 # 只有接螢幕的主機(desktop'.*)
│   ├── input-method/        # fcitx5 與語音輸入
│   └── power/               # 筆電電源:upower、power-profiles-daemon
└── server/                  # 只有伺服器:fail2ban、initrd 遠端解鎖(server'.*)
```

子目錄只用來分組，不增加命名空間層級，例如 `desktop/input-method/fcitx5.nix`
的選項是 `desktop'.fcitx5`。

## 判斷放哪裡

- 伺服器也可能用到 → `base/`。例如 SSH、防火牆、快照、zram。
- 一定要有螢幕才有意義 → `desktop/`。例如登入畫面、視窗管理器、輸入法。
- 只有伺服器需要，桌面不會開 → `server/`。

## 持久化

根目錄是 tmpfs，重開機即清空，只有登記過的路徑會留下：

- 系統狀態用 `preservation'.os.*`。
- 使用者狀態用 `preservation'.user.*`；Home Manager 模組改用 `persist'`，
  由 `base/hardware/persistence.nix` 併入。
- 含金鑰、憑證或私人資料的目錄加上 `mode = "0700"`；未宣告時為 `0755`，
  而且每次開機都會套用。
- 服務也可能由上游模組啟用時，依服務的最終狀態登記，例如
  `lib.optionals config.hardware.bluetooth.enable [ ... ]`，而不是看本模組的開關。
