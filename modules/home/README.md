# Home Manager 模組

使用者層的程式與設定。`base/` 只放每臺主機都一律生效的東西，可以開關的功能放在 `nixos/`。

```text
home/
├── base/                    # 一律生效、沒有開關,伺服器、桌面、macOS 都能用
│   ├── core/                # 無法依介面分類的:home、persist
│   ├── cli/                 #   git、packages、shell、ssh
│   ├── tui/                 #   lazygit、monitoring
│   └── gui/                 #   目前沒有內容,以 .gitkeep 佔位
├── nixos/                   # 可開關的功能,預設關閉
│   ├── cli/                 # 命令列工具,不佔用整個終端機(cli'.*)
│   │                        #   development、toolchain
│   ├── tui/                 # 佔用整個終端機的介面(tui'.*)
│   │   └── agents/          #   claude-code、dsh
│   └── gui/                 # 開啟視窗的程式(gui'.*)
│       ├── browsers/        #   chrome、firefox
│       ├── editors/         #   vscode、zed
│       └── kitty、claude-desktop、主題、游標、XDG、其他桌面程式
└── darwin/                  # 只有 macOS,預留
```

## 放在哪裡

1. 每臺主機都需要、不用開關，而且在伺服器、桌面與 macOS 上都能用 → `base/`。
   只放簡單、通用的東西，例如 shell、Git、日常命令列工具。依介面放進 `cli/`、
   `tui/`、`gui/`；無法分類但每臺都需要的，例如帳號設定與 `persist'` 選項，放 `core/`。
   四個目錄都要保留，沒有內容時以 `.gitkeep` 佔位。
2. 主機要能選擇開或不開的功能 → `nixos/`，例如開發環境、程式語言工具鏈、
   AI agent、圖形介面程式。
3. 只有 macOS 才用 → `darwin/`。

`base/` 與 `nixos/` 底下都依介面分類：不佔用終端機的放 `cli/`，佔用整個終端機的放 `tui/`，
開啟視窗的放 `gui/`。選項命名空間跟著介面分類：`nixos/gui/theme.nix` 的選項是 `gui'.theme`。

## 開關

`base/` 的模組一律生效，沒有 `enable`。`nixos/` 的模組都預設關閉，主機在
`default.nix` 以 `hm'` 打開：

```nix
hm' = {
  cli'.development.enable = true;
  tui'.claude-code.enable = true;
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
例如 go-build 在 `nixos/cli/toolchain.nix`。系統層模組不經過 `persist'`，直接寫
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
