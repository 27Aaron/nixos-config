# nix-darwin 模組

只有 macOS 系統層才載入的模組，例如 Homebrew、Dock、系統偏好設定。
與 NixOS 共用的部分放 `../base/`，使用者層的設定放 `../home/darwin/`。

目前沒有 nix-darwin 主機，此目錄預留。加入第一臺 Mac 時，需要先在 flake
加入 `nix-darwin` 輸入，並由 `hosts/default.nix` 收集 `base/` 與這裡的模組。
