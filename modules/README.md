# 模組目錄

這裡放所有可重用的 NixOS、nix-darwin 與 Home Manager 模組，按平臺與用途分類。`hosts/<name>/`
只負責開關功能，具體實作都在這裡。

## 目錄結構

```text
modules/
├── default.nix                  # 走訪整棵樹，定義 user' 與 hm' 別名
├── base/                        # 預留：NixOS 與 nix-darwin 完全相同的設定
├── darwin/                      # 預留：nix-darwin 系統模組
├── nixos/
│   ├── base/                    # 每一臺 NixOS 都可能用到
│   │   ├── core/                #   身分、使用者與管理面（core'.*）
│   │   │   ├── firewall.nix     #     nftables 防火牆
│   │   │   ├── fish.nix         #     系統層 fish 與使用者登錄 shell
│   │   │   ├── host.nix         #     使用者、主機名、時區
│   │   │   ├── i18n.nix         #     語系設定
│   │   │   ├── logging.nix      #     journal 與 core dump 容量上限
│   │   │   ├── nix.nix          #     nix 設定、快取與 flake 路徑
│   │   │   ├── sops.nix         #     sops-nix 解密
│   │   │   └── yubikey.nix      #     YubiKey 工具與智慧卡
│   │   ├── hardware/            #   機器物理上有什麼（hardware'.*）
│   │   │   ├── boot/
│   │   │   │   ├── initrd-ssh.nix    # 遠端解鎖 LUKS 用的 initrd SSH
│   │   │   │   └── systemd-boot.nix  # systemd-boot 開機管理器
│   │   │   ├── amdgpu.nix       #     AMD 顯示晶片與 OpenCL
│   │   │   ├── bluetooth.nix    #     藍牙
│   │   │   ├── brightness.nix   #     螢幕背光控制
│   │   │   ├── disko.nix        #     磁碟分割、LUKS、Btrfs 子卷
│   │   │   └── persistence.nix  #     tmpfs 根目錄的狀態保留
│   │   └── services/            #   常駐守護行程（services'.*）
│   │       ├── btrbk.nix        #     Btrfs 本機快照
│   │       ├── btrfs-scrub.nix  #     Btrfs 定期檢查
│   │       ├── dae.nix          #     透明代理
│   │       ├── fail2ban.nix     #     登入失敗封鎖
│   │       ├── keyd.nix         #     系統層按鍵重映射
│   │       ├── logrotate.nix    #     日誌輪替
│   │       ├── networkmanager.nix #   網路管理
│   │       ├── openssh.nix      #     SSH 服務與客戶端
│   │       ├── pipewire.nix     #     音訊堆疊
│   │       ├── power-profiles-daemon.nix # 電源設定檔
│   │       ├── smartd.nix       #     磁碟健康監控
│   │       ├── trash.nix        #     回收桶保留期限
│   │       ├── upower.nix       #     電池狀態回報
│   │       ├── vnstat.nix       #     流量統計
│   │       └── zram.nix         #     壓縮 swap
│   ├── desktop/                 # 有螢幕的主機（desktop'.*）
│   │   ├── fcitx5.nix           #   輸入法框架與 rime
│   │   ├── file-manager.nix     #   Nautilus 與回收桶整合
│   │   ├── fonts.nix            #   系統字型
│   │   ├── greetd.nix           #   登入管理器
│   │   ├── niri.nix             #   Niri 合成器工作階段
│   │   ├── noctalia.nix         #   Noctalia 桌面外殼
│   │   └── vinput.nix           #   語音輸入
│   └── server/                  # 預留：無頭主機專用
└── home/                        # Home Manager
    ├── default.nix              # 平臺入口：import ./base 與 ./nixos
    ├── base/
    │   ├── default.nix          # 共用清單：persist' 選項與帳號設定
    │   ├── core/                #   自己不畫介面
    │   │   ├── development.nix  #     direnv、mise、uv
    │   │   ├── git.nix          #     Git 身分與 delta
    │   │   ├── packages.nix     #     只安裝不配置的命令列工具
    │   │   ├── shell.nix        #     fish、zsh、提示符與歷史
    │   │   └── toolchain.nix    #     語言直譯器與語言伺服器
    │   ├── tui/                 #   接管整個終端
    │   │   ├── agents/          #     claude-code、dsh
    │   │   ├── git/lazygit.nix  #     Git 終端介面
    │   │   └── monitoring.nix   #     btop、ncdu、nload
    │   └── gui/                 #   開一個視窗
    │       ├── agents/          #     claude-desktop、dsh-desktop
    │       ├── browsers/        #     chrome、firefox
    │       ├── editors/         #     vscode、zed
    │       ├── terminal/kitty.nix #   終端機模擬器
    │       ├── mime-apps.nix    #     預設開啟程式
    │       ├── nagram.nix       #     Telegram 客戶端
    │       ├── pointer-cursor.nix #   滑鼠指標主題
    │       ├── seahorse.nix     #     GNOME 鑰匙環管理
    │       ├── theme.nix        #     Catppuccin 與 GTK/Qt 主題
    │       └── user-dirs.nix    #     XDG 使用者目錄
    ├── nixos/                   #   只有 NixOS 需要的設定
    │   ├── default.nix          #     入口
    │   └── magpie.nix           #     托盤程式與本機模型閘道
    └── darwin/                  #   預留：只有 macOS 需要的設定
```

## 分層規則

三問依序決定位置，先能回答的那個就定案：

1. **哪個平臺？** `base/` 通用，`nixos/` 只給 NixOS，`darwin/` 只給 nix-darwin。
2. **系統還是使用者？** `modules/nixos/` 與 `modules/darwin/` 設系統選項；`modules/home/` 設
   Home Manager 選項。
3. **哪個角色、哪種形態？** 系統模組按角色分 `base`、`desktop`、`server`；Home Manager 模組按
   「程式畫什麼」分 `core`、`tui`、`gui`。

`base/` 的意思是「任何一臺都可能用到」，不是「每一臺都要打開」——開關寫在
`hosts/<name>/default.nix`。

## Home Manager 的三個桶

判斷法只有一句：**程式執行時佔不佔畫面？**

| 桶      | 標準                       | 例子                            |
| ------- | -------------------------- | ------------------------------- |
| `core/` | 完全不佔，印完就退出       | fd、ripgrep、jq、fastfetch、duf |
| `tui/`  | 佔滿終端，需要已存在的終端 | btop、ncdu、lazygit、nvim       |
| `gui/`  | 開一個自己的視窗           | kitty、chrome、zed、nagram      |

終端機模擬器（kitty）屬 `gui/terminal/`：它就是那個終端，不依賴別的終端。`ncdu` 與 `duf` 用途
幾乎一樣，但 `duf` 印完就退回、`ncdu` 停在畫面等按鍵，所以分屬兩桶。

## 持久化

根目錄是 tmpfs，重開機即清空，只有登記過的路徑會留下。

- **系統側**用 `preservation'.os.*`、`preservation'.user.*`。
- **Home Manager 側**用 `persist'.directories`、`persist'.files`（相對於家目錄），由
  `nixos/base/hardware/persistence.nix` 併進 `preservation'.user`。

**登記放在擁有該狀態的模組裡**，不要集中到 `persistence.nix`。例如 nix 的快取在
`core/nix.nix`、鑰匙環在 `home/base/gui/seahorse.nix`。`persistence.nix` 只留沒有專屬模組可歸的
系統路徑（`/var/lib/nixos`、`/var/log` 等）與 GPG 金鑰環。

`~/.cache` 不整體持久化：它幾乎全是可重建內容且成長很快，只有真正需要的快取才逐項登記。

## 新增模組

1. 用上面的三問確定位置，**新建檔案，不要新增頂層目錄**。
2. 系統模組：`options.<namespace>.enable = lib.mkEnableOption "…";`，內容包在
   `config = lib.mkIf cfg.enable { … };`。
3. Home Manager 模組：要加到 `modules/home/base/default.nix` 的 import 清單；NixOS 模組自動載入。
4. 執行 `nix fmt` 與 `just check`。

## Darwin 待辦

`base/`、`darwin/`、`nixos/server/`、`home/darwin/` 目前是空佔位。接 macOS 主機前需要：

- `flake.nix` 加上 `nix-darwin` input 與 `darwinConfigurations` 輸出；
- `modules/default.nix` 改成分平臺走訪，NixOS 走 `base` ＋ `nixos`，darwin 走 `base` ＋ `darwin`；
- darwin 入口 import `home/base` ＋ `home/darwin`，避開 `home/nixos/`。
