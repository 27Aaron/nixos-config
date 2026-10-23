# 系統層共用模組

NixOS 與 nix-darwin 都會載入這裡的模組，因此只能使用兩邊都有的選項，例如
`nix.settings`、`programs.fish`、`users.users`。只有 NixOS 才有的設定，例如 `systemd`、
`boot`、持久化，放到 `nixos/`。

目前還沒有 nix-darwin 主機，這裡的模組只經過 NixOS 驗證；加入第一臺 Mac 時要再實際建置確認。
