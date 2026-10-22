# river

MECHREVO 無界 14XA（WUJIE 14X Blizzard）筆電，Ryzen 7 8845HS。

## 硬體

| 項目 | 規格 | ID／備註 |
|---|---|---|
| 型號 | MECHREVO WUJIE14XA，主機板 WUJIE14-GX4HRXL | |
| BIOS | N.1.14MRO50（2025-11-13） | 更新方式見下方 |
| CPU | AMD Ryzen 7 8845HS（Phoenix / Hawk Point），8 核心 16 執行緒 | |
| 記憶體 | 32 GB（2 × 16 GB）DDR5-5600，Crucial CT16G56C46S5.C8D | |
| GPU | Radeon 780M（HawkPoint1） | `1002:1900` |
| Wi-Fi | MediaTek MT7922（RZ616），驅動 mt7921e | `14c3:7922` |
| 藍牙 | MT7922 的藍牙部分 | `13d3:3585` |
| 乙太網路 | Motorcomm YT6801，需要 Linux 7.0 以上 | `1f0a:6801` |
| 觸控板 | UNIW0001:00 093A:0255，走 I2C 而非 PS/2 | 休眠恢復後需重綁，見 `power.nix` |
| 音訊 | Radeon HD Audio、Ryzen HD Audio | `1002:1640`、`1022:15e3` |
| USB4 | 單條 USB-C 線即可輸出影像 | `1022:1669` |
| 儲存 | Micron 2550 NVMe SSD，1 TB（CT1000P3PSSD8） | |
| TPM | 有（`/dev/tpm0`） | |
| 感測器 | k10temp、amdgpu、nvme、BAT0、spd5118 × 2 | |
| 睡眠 | 只有 s2idle，沒有 S3 | 合蓋行為見 `power.nix` |
| 鏡頭 | IR 鏡頭 | `04f2:b7dd` |

## 設定檔

| 檔案 | 內容 |
|---|---|
| `default.nix` | 功能開關、時區、`stateVersion` |
| `hardware.nix` | 開機載入器、核心、initrd、韌體與週邊 |
| `storage.nix` | 磁碟佈局（LUKS + FIDO2、Btrfs）、持久化、zram、磁碟維護 |
| `power.nix` | 休眠與睡眠、蓋子與觸控板的恢復修補、電源管理服務 |
| `keyboard.nix` | keyd 鍵位映射（Copilot 鍵、HHKB） |

## BIOS

BIOS 更新程式只有 Windows 的 `.EXE`。

- **下載：**[N.1.14MRO50](https://driver.mechrevo.com/d.mechrevo.com/driver/MECHREVO2024/WJ14X8845HS/GXxHXxxN114MRO50_CAP.EXE)
- **來源：**[w568w 的 WUJIE 14XA 逆向筆記](https://gist.github.com/w568w/b2fc5f9d1f4dff13efe751abec27b396?permalink_comment_id=6147538#gistcomment-6147538)

## 重灌

硬碟損壞、換新硬碟，或想從頭安裝時，照以下步驟從 NixOS 安裝隨身碟重建 river。重灌只會恢復**系統設定**；`/persistent` 裡的資料（瀏覽器設定檔、Nagram 登入狀態、文件等）沒有備份，會一併消失。

### 平時就要保管好的東西

| 項目 | 用途 | 遺失時 |
|---|---|---|
| `~/.ssh/id_ed25519` | sops 用它解密帳號密碼與 dae 設定；也用來連 GitHub | 見下方「SSH 金鑰遺失時」 |
| LUKS 密碼 | 沒有 FIDO2 鑰匙時解鎖磁碟 | 重灌時會設定新的 |
| FIDO2 鑰匙與 PIN | 開機解鎖磁碟 | 重灌時用新鑰匙登記即可 |
| 帳號密碼 | 登入與 sudo | 在 nix-secrets 的 `users/password.yaml` 換一個新的雜湊 |

**重灌在同一顆硬碟上之前，先把 `~/.ssh/id_ed25519` 複製到隨身碟**：第 4 步會清空整顆磁碟。

### 步驟

安裝隨身碟上預設是 bash，以下指令都以 root 執行。

**1. 準備環境**

從 NixOS 安裝隨身碟開機並連上網路：有線網路通常會自動連上；Wi-Fi 在圖形版用右上角的網路設定，最小版用 `wpa_cli`。然後：

```bash
sudo -i
export NIX_CONFIG="experimental-features = nix-command flakes"
```

**2. 放回 SSH 金鑰**

flake 的 `secrets` 輸入是私有的 nix-secrets，要用這把金鑰才抓得到：

```bash
install -d -m 700 /root/.ssh
install -m 600 /path/to/id_ed25519 /root/.ssh/id_ed25519
install -m 644 /path/to/id_ed25519.pub /root/.ssh/id_ed25519.pub
ssh -T git@github.com    # 應顯示 Hi 27Aaron!
```

**3. 取得設定**

```bash
nix shell nixpkgs#git -c git clone git@github.com:27Aaron/nixos-config.git /root/nixos-config
cd /root/nixos-config
```

換了新硬碟的話，先用 `ls -l /dev/disk/by-id/` 找到新硬碟，改掉 `storage.nix` 的 `device`。

**4. 分割、加密並掛載磁碟**

⚠️ 這一步會**清空整顆硬碟**。

```bash
nix run --inputs-from . disko -- --mode destroy,format,mount --flake .#river
```

`--inputs-from .` 讓它使用 flake.lock 鎖定的 disko 版本。過程中會要求設定 LUKS 密碼；完成後所有檔案系統掛在 `/mnt` 下。

**5. 登記 FIDO2 鑰匙**

只插一把鑰匙，會依序要求 LUKS 密碼、PIN 與觸摸：

```bash
systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/disk-main-luks
```

有第二把鑰匙的話，換上後再執行一次。

**6. 量測休眠用的 `resume_offset`**

swapfile 是新建的，位置會變：

```bash
btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile
```

數字和 `power.nix` 的 `resume_offset=…` 不同的話，改成新的值，否則休眠後無法恢復。

**7. 放好開機需要的持久化檔案**

sops 在開機時從 `/persistent/home/aaron/.ssh/id_ed25519` 讀金鑰，沒有它就解不開帳號密碼，開機後會無法登入。

```bash
install -d -m 700 -o 1000 -g 100 /mnt/persistent/home/aaron /mnt/persistent/home/aaron/.ssh
install -m 600 -o 1000 -g 100 /root/.ssh/id_ed25519 /mnt/persistent/home/aaron/.ssh/
install -m 644 -o 1000 -g 100 /root/.ssh/id_ed25519.pub /mnt/persistent/home/aaron/.ssh/
cp -a /root/nixos-config /mnt/persistent/home/aaron/
chown -R 1000:100 /mnt/persistent/home/aaron/nixos-config
install -d /mnt/persistent/etc
systemd-machine-id-setup --root /mnt/persistent
```

UID 1000、GID 100 是 aaron 與 `users` 群組；最後一行預先建立 machine-id，免得第一次開機前它是空的。

**8. 安裝**

```bash
nixos-install --flake /root/nixos-config#river --no-root-passwd \
  --option extra-substituters "https://cache.numtide.com https://fcitx5-vinput.cachix.org" \
  --option extra-trusted-public-keys "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU="
```

- `--no-root-passwd`：root 的密碼來自 sops，不在這裡設定。
- 兩個 `--option`：安裝隨身碟不認識這兩個二進位快取，少了它們，claude-code 與 sherpa-onnx 都要在本機編譯，會非常久。金鑰與 `modules/base/core/nix.nix` 相同。

**9. 重開機並確認**

拔掉隨身碟重開機，用 FIDO2 鑰匙解鎖磁碟，然後確認：

```bash
sudo -k && sudo true          # 帳號密碼能用,代表 sops 解密成功
systemctl --failed
systemctl status dae
```

第 3、6 步若改了 `storage.nix` 或 `power.nix`，記得在 `~/nixos-config` 提交並推送。SSH 主機金鑰是重新產生的，其他機器連進來時會提示主機金鑰已變更，更新它們的 `known_hosts` 即可。

### SSH 金鑰遺失時

沒有 `id_ed25519` 就解不開 river 的秘密，要先從 MacBook 加入一把新金鑰：

1. 在安裝隨身碟上產生新金鑰，取得它的 age 公鑰：

   ```bash
   install -d -m 700 /root/.ssh
   ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
   nix shell nixpkgs#ssh-to-age -c ssh-to-age < /root/.ssh/id_ed25519.pub
   ```

2. 在 MacBook 上：
   - 把 `/root/.ssh/id_ed25519.pub` 的內容加到 GitHub 的 SSH 金鑰。
   - 在 nix-secrets 把 `.sops.yaml` 的 `&River` 換成新的 age 公鑰，執行 `just rekey`（MacBook 的金鑰打得開所有檔案），提交並推送。
3. 回到安裝隨身碟，照上面的步驟繼續；在第 3 步 clone 之後，先執行 `nix flake update secrets`，讓安裝使用重新上鎖的版本。
