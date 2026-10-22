# NixOS 模組

只有 NixOS 才載入的模組。依用途分成三類，伺服器只開它需要的功能。

```text
nixos/
├── base/                # 任何 NixOS 都可能用到,包括伺服器與路由器
│   ├── core/            # 身分、使用者、nix、日誌等基礎(core'.*)
│   ├── hardware/        # 機器上有什麼硬體(hardware'.*)
│   │   └── boot/        # 開機管理與 initrd
│   └── services/        # 常駐服務(services'.*)
├── desktop/             # 只有接螢幕的主機(desktop'.*)
└── server/              # 只有伺服器(server'.*),預留
```

## 判斷放哪裡

- 伺服器也可能用到 → `base/`。例如 SSH、防火牆、快照、zram。
- 一定要有螢幕才有意義 → `desktop/`。例如登入畫面、視窗管理器、輸入法。
- 只有伺服器需要，桌面不會開 → `server/`。

## 持久化

根目錄是 tmpfs，重開機即清空，只有登記過的路徑會留下：

- 系統狀態用 `preservation'.os.*`。
- 使用者狀態用 `preservation'.user.*`；Home Manager 模組改用 `persist'`，
  由 `base/hardware/persistence.nix` 併入。
