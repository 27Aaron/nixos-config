# 系統層共用模組

NixOS 與 nix-darwin 都會載入這裡的模組，所以只能使用兩邊都有的選項，例如 `nix.settings`、`programs.fish`、`users.users`。只有 NixOS 才有的設定，例如 `systemd`、`boot`、持久化，放到 `nixos/`。
