# Home Manager 模組

使用者層的程式與設定。先依平臺分成三個目錄，各自再依程式的介面分類。

```text
home/
├── base/                    # Mac 和 Linux 共用
│   ├── core/                # 一律生效:帳號設定、persist' 選項
│   ├── cli/                 # 命令列工具,不佔用整個終端機(cli'.*)
│   │                        #   development、git、packages、shell、ssh、toolchain
│   ├── tui/                 # 佔用整個終端機的介面(tui'.*)
│   │   ├── agents/          #   claude-code、dsh
│   │   └── lazygit.nix、monitoring.nix
│   └── gui/                 # 開啟視窗的程式(gui'.*)
│       ├── browsers/        #   chrome、firefox
│       ├── editors/         #   vscode、zed
│       └── kitty.nix、claude-desktop.nix
├── nixos/                   # 只有 Linux
│   └── gui/                 # GTK/Qt 主題、游標、XDG、Linux 專屬程式(gui'.*)
└── darwin/                  # 只有 macOS,預留
```

## 放在哪裡

1. 依平臺：Mac 也能用就放 `base/`，否則放 `nixos/` 或 `darwin/`。
   不確定時，查套件在 `aarch64-darwin` 上是否可用；依賴 systemd、XDG、GTK 的一律放 `nixos/`。
2. 依介面：不佔用終端機的放 `cli/`，佔用整個終端機的放 `tui/`，開啟視窗的放 `gui/`。

選項命名空間跟著介面分類，不分平臺：`nixos/gui/theme.nix` 的選項是 `gui'.theme`。

## 開關

`core/` 以外的模組都預設關閉，主機在 `default.nix` 以 `hm'` 打開：

```nix
hm' = {
  cli'.git.enable = true;
  tui'.lazygit.enable = true;
  gui'.zed.enable = true;
};
```

## 載入方式

NixOS 主機由 `nixos/base/core/home-manager.nix` 自動收集 `base/` 與 `nixos/`；
新增檔案不必手動登記。

## 持久化

在 NixOS 上，家目錄同樣位於 tmpfs。模組以 `persist'.directories`、`persist'.files`
回報要保留的路徑（相對於家目錄）。其他平臺不讀取這兩個選項，宣告了也沒有影響。

`~/.cache` 不整體保留，只有真正需要的快取才逐項登記，而且登記在產生它的模組裡，
例如 go-build 在 `base/cli/toolchain.nix`。系統層模組不經過 `persist'`，直接寫
`preservation'.user`，例如縮圖在 `modules/nixos/desktop/file-manager.nix`。

含憑證、登入狀態或歷史紀錄的目錄一律加上 `mode = "0700"`：

```nix
persist'.directories = [
  {
    directory = ".config/gh";
    mode = "0700";
  }
];
```

preservation 每次開機都會把目錄權限設回宣告的值，未宣告時是 `0755`。
