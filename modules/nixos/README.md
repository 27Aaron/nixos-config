# NixOS 模組

只有 NixOS 才載入的模組，依用途分成三類。

```text
nixos/
├── base/       # 任何 NixOS 都可能用到,包括伺服器:core/、hardware/、services/
├── desktop/    # 只有接螢幕的主機
└── server/     # 只有伺服器
```

## 放在哪裡

- 伺服器也可能用到 → `base/`，例如 SSH、防火牆、快照。
- 一定要有螢幕才有意義 → `desktop/`，例如登入畫面、視窗管理器、輸入法。
- 只有伺服器需要 → `server/`。

子目錄只用來分組，不增加命名空間層級。

## 持久化

根目錄是 tmpfs，只有登記過的路徑會留下。系統狀態登記在 `preservation'.os`，使用者狀態登記在
`preservation'.user`。含金鑰、憑證或私人資料的目錄加上 `mode = "0700"`。
