# 系統層共用模組

NixOS 與 nix-darwin 都會載入這裡的模組，因此只能使用兩邊都有的選項，例如
`nix.settings`、`fonts.packages`、`programs.fish`、`users.users`。

```text
base/
└── core/              # 一律生效,沒有開關
    ├── aliases.nix    # user' 與 hm' 別名
    ├── fish.nix       # fish 作為登入 shell
    └── nix.nix        # nix 設定、快取、allowUnfree
```

放進這裡之前，先確認選項在兩個平臺都存在。只有 NixOS 才有的設定，例如
`systemd`、`boot`、`preservation'`，要放到 `nixos/`。

目前還沒有 nix-darwin 主機，這裡的模組只經過 NixOS 驗證；加入第一臺 Mac 時，
要再實際建置一次確認。
