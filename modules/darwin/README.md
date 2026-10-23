# nix-darwin 模組

只有 macOS 系統層才載入的模組，例如 Homebrew、Dock、系統偏好設定。
與 NixOS 共用的部分放 `../base/`，使用者層的設定放 `../home/darwin/`。

```text
darwin/
├── core/          # 一律生效:主機名稱、使用者、時區、安全性
│   └── defaults/  # system.defaults 系統偏好設定,依設定頁面分檔
└── programs/      # 主機可以選擇開關的程式,例如 Homebrew
```

子目錄只用來分組，不增加命名空間層級。

目前沒有 nix-darwin 主機，此目錄的模組尚未經過評估與建置。加入第一臺 Mac 時，需要先在 flake
加入 `nix-darwin` 輸入，並由 `hosts/default.nix` 收集 `base/` 與這裡的模組。

## 系統偏好設定

優先使用 nix-darwin 的 `system.defaults` 選項，沒有原生選項時才寫入 `CustomUserPreferences`，
寫入的結果可用 `defaults read` 確認。

- 選項說明：<https://nix-darwin.github.io/nix-darwin/manual/>
- `defaults` 鍵值參考：<https://github.com/yannbertrand/macos-defaults>
- 未文件化的鍵值參考 m-cli：<https://github.com/rgcr/m-cli>
