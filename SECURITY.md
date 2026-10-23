# Security

這份設定如何保持安全：它強制執行的控制與檢查方式、它信任的 flake 輸入，以及機密、更新與事件處理的流程。以 Nix 寫下的控制不代表它在執行中的機器上真的生效；[執行期檢查](#runtime-checks)才能證明。已接受的例外記錄在 [WORKAROUNDS.md](WORKAROUNDS.md#security-exceptions)。

## Controls and how they are checked

[`tests/`](tests/README.md) 的 eval 測試在每次 `just check` 時執行，控制退化時檢查就會失敗。NixOS 主機執行 [`shared.nix`](tests/security/shared.nix) 與 [`nixos.nix`](tests/security/nixos.nix)；nix-darwin 主機執行 [`shared.nix`](tests/security/shared.nix) 與 [`darwin.nix`](tests/security/darwin.nix)。

| 控制 | 位置 | 測試 |
|---|---|---|
| 沒有 Nix 受信任使用者，daemon 只限 `@wheel`（macOS 為 `@admin`），必須有簽章 | [`modules/base/core/nix.nix`](modules/base/core/nix.nix)、[`modules/nixos/base/core/nix.nix`](modules/nixos/base/core/nix.nix)、[`modules/darwin/core/nix.nix`](modules/darwin/core/nix.nix) | `nix-trust`、`daemon-access` |
| 受信任 substituter 與金鑰的清單 | [`modules/base/core/nix.nix`](modules/base/core/nix.nix)、[`modules/nixos/desktop/input-method/vinput.nix`](modules/nixos/desktop/input-method/vinput.nix)（只在 `desktop'.vinput` 時） | `nix-caches` |
| sshd：只接受金鑰，除非 `services'.openssh.rootLogin` 否則不允許 root 登入，不允許 X11 轉送 | [`modules/nixos/base/services/openssh.nix`](modules/nixos/base/services/openssh.nix) | `ssh` |
| 各主機防火牆對外連接埠的清單 | 開啟連接埠的服務 | `firewall` |
| 設定裡沒有密碼或雜湊；密碼在建立使用者之前解密 | [`modules/nixos/base/core/users.nix`](modules/nixos/base/core/users.nix) | `password-source` |
| sops 只用使用者的 SSH 金鑰解密，沒有金鑰檔 | [`modules/nixos/base/core/sops.nix`](modules/nixos/base/core/sops.nix)、[`modules/darwin/core/sops.nix`](modules/darwin/core/sops.nix) | `sops-key` |
| systemd-boot 編輯器關閉（lanzaboote 下也是），使用者不可變更 | [`modules/nixos/base/hardware/boot/`](modules/nixos/base/hardware/boot/)、[`users.nix`](modules/nixos/base/core/users.nix) | `boot-and-accounts` |
| 以 lanzaboote 搭配擁有者自行產生的金鑰做 Secure Boot；金鑰以 `0700` 持久化（river、elaina） | [`modules/nixos/base/hardware/boot/lanzaboote.nix`](modules/nixos/base/hardware/boot/lanzaboote.nix) | `boot-and-accounts`、`private-state` |
| TPM2 磁碟解鎖只用於 Secure Boot 主機，綁定 PCR 7 | [`modules/nixos/base/hardware/disko.nix`](modules/nixos/base/hardware/disko.nix) | 模組 assertion |
| 核心 sysctl 基準、禁止載入的模組、保留 user namespace、相容休眠 | [`modules/nixos/base/core/kernel-hardening.nix`](modules/nixos/base/core/kernel-hardening.nix) | `kernel` |
| 編輯器與代理的信任提示保持開啟 | [`modules/home/nixos/gui/editors/`](modules/home/nixos/gui/editors/)、[`modules/home/nixos/tui/agents/`](modules/home/nixos/tui/agents/)、[`modules/home/shared/tui/agents/`](modules/home/shared/tui/agents/) | `editor-and-agent-trust` |
| 憑證與歷史紀錄目錄以 `0700` 持久化 | 各模組的 `persist` 項目 | `private-state` |
| btrbk 依賴 sudo 期間 `execWheelOnly` 保持關閉 | [`modules/nixos/base/services/btrbk.nix`](modules/nixos/base/services/btrbk.nix) | `btrbk-sudo` |
| 沙箱化的程式只以 nixpak 版本安裝 | [`modules/home/nixos/gui/nagram.nix`](modules/home/nixos/gui/nagram.nix)、[`lib/nixpak/`](lib/nixpak/) | `sandboxed-apps` |

程式符合以下條件時就放進 nixpak 沙箱：來自第三方、會處理不受信任的內容，而且不需要使用者的檔案。

### Runtime checks

switch 或重開機動到安全設定後執行這些檢查。NixOS 上：

```bash
nix config show trusted-users                      # root
nix config show allowed-users                      # @wheel
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication) '   # no / no
sudo nft list chain inet nixos-fw input-allow      # 只有預期的連接埠
systemctl --failed
bootctl status | grep 'Secure Boot'             # enabled (user)，Secure Boot 主機上
sudo sbctl verify                                  # 所有 stub 都已簽章，Secure Boot 主機上
```

macOS 上：

```bash
nix config show trusted-users                      # root
nix config show allowed-users                      # @admin
```

## Flake inputs

下列每個輸入都能改變機器上執行的東西；提供系統模組的輸入會在啟用時以 root 執行。把更新當成一次供應鏈事件來審查，依照 [`AGENTS.md` 的〈Flake lock bumps〉](AGENTS.md#flake-lock-bumps)。

| 輸入 | 提供 | 追蹤 |
|---|---|---|
| `nixpkgs` | 所有東西 | `nixos-unstable` |
| `nix-darwin` | nix-darwin 系統 | 預設分支 |
| `home-manager` | 使用者環境 | 預設分支 |
| `disko` | NixOS 檔案系統 | 預設分支 |
| `preservation` | NixOS 持久化 | 預設分支 |
| `lanzaboote` | Secure Boot 開機載入程式與簽章工具 | 發行標籤 |
| `sops-nix` | 機密解密 | 預設分支 |
| `llm-agents` | 程式碼代理；受信任快取 | 預設分支 |
| `nagram` | Nagram 桌面版 | 預設分支 |
| `fcitx5-vinput` | fcitx5 附加元件；受信任快取 | 標籤（[WA-001](WORKAROUNDS.md#pins)） |
| `nixpak` | 程式沙箱包裝 | 預設分支 |
| `nur-packages`、`fonts`、`secrets` | 擁有者自己的儲存庫 | 預設分支 |

macOS 上的 Homebrew 套件不受 flake 鎖定，另外更新。

## Secrets

機密放在私人的 nix-secrets 儲存庫，由 sops-nix 在啟用時以各主機的 `~/.ssh/id_ed25519`（ed25519，無密語）解密。

不用 root 編輯機密：

```fish
set -x SOPS_AGE_KEY (ssh-to-age -private-key -i ~/.ssh/id_ed25519)
sops users/password.yaml
set -e SOPS_AGE_KEY
```

更換主機的金鑰：

1. 以另一個名稱產生新金鑰，並用 `ssh-to-age < new.pub` 印出它的收件人。
2. 在 nix-secrets 裡替換 `.sops.yaml` 中該主機的收件人，並用仍能解密的金鑰對每個檔案執行 `sops updatekeys`。
3. 更新這裡的 `secrets` 輸入，再把新金鑰移到 `~/.ssh/id_ed25519` 並 switch。

## Secure Boot

啟用 `hardware'.lanzaboote` 的主機以 systemd-boot stub 開機，stub 以擁有者自行產生、存放在 `/var/lib/sbctl` 的金鑰簽章，並以 `0700` 持久化。依下列順序設定主機；在金鑰登記到韌體之前，每一步都能靠切回 `hardware'.systemd-boot` 復原。

1. 建立金鑰，再複製到持久化磁碟區。這要在第一次 switch 之前做：preservation 會把 `/persistent/var/lib/sbctl` bind mount 到 `/var/lib/sbctl` 上，空的持久化副本會蓋掉新金鑰。

   ```bash
   sudo nix shell nixpkgs#sbctl -c sbctl create-keys
   sudo cp -a /var/lib/sbctl /persistent/var/lib/
   sudo chmod 700 /persistent/var/lib/sbctl
   sudo ls /var/lib/sbctl/keys /persistent/var/lib/sbctl/keys   # 兩邊都有 PK、KEK 與 db
   ```

2. 以 `hardware'.lanzaboote` 取代 `hardware'.systemd-boot`，再執行 `just switch`。`sudo sbctl verify` 必須回報除了 `/boot/EFI/nixos/` 底下的核心與 initrd 以外，每個檔案都已簽章。移除原本 systemd-boot 留下的項目：lanzaboote 不再更新它們，而且它們會啟動未簽章的核心；`/boot` 只有 root 能讀，所以萬用字元要在 root shell 裡展開：

   ```bash
   sudo sh -c 'rm -v /boot/loader/entries/nixos-*.conf'
   sudo bootctl list | grep source   # 只剩 /boot/EFI/Linux/nixos-generation-*.efi
   ```
3. 在 Secure Boot 仍關閉的狀態下重開機一次，確認主機能開機，而且 `/var/lib/sbctl/keys` 還在。
4. 在韌體裡設定韌體密碼，並清除平臺金鑰讓 Secure Boot 進入 Setup Mode（選項名稱類似 *Reset To Setup Mode* 或 *Delete PK*）。不要清除所有 Secure Boot 變數：那也會刪掉撤銷清單（dbx）。
5. 回到 NixOS，`sudo sbctl status` 必須顯示 `Setup Mode: ✗ Enabled`，才能用 `sudo sbctl enroll-keys` 登記金鑰。許多韌體要到下次開機才會離開 Setup Mode，所以重開機，若 Secure Boot 是關閉的就在韌體裡打開，並確認 `bootctl status` 顯示 `Secure Boot: enabled (user)`。

如果主機必須能啟動 Microsoft 簽章的媒體，或韌體會載入 option ROM（以 Microsoft 的金鑰簽章，否則會被拒絕），就在 `enroll-keys` 加上 `--microsoft`。TPM 事件紀錄會把每個 option ROM 記為 `EV_EFI_BOOT_SERVICES_DRIVER` 事件；第二個指令用來確認紀錄確實有被讀到。

```bash
sudo nix shell nixpkgs#tpm2-tools -c sh -c 'tpm2_eventlog /sys/kernel/security/tpm0/binary_bios_measurements' | grep -c EV_EFI_BOOT_SERVICES_DRIVER
sudo nix shell nixpkgs#tpm2-tools -c sh -c 'tpm2_eventlog /sys/kernel/security/tpm0/binary_bios_measurements' | grep -c EventType
```

Secure Boot 開啟後，啟用 `hardware'.disko.luks.tpm2` 的主機就能以 TPM 解鎖磁碟。金鑰只綁定 PCR 7，它記錄 Secure Boot 狀態與驗證開機載入程式的憑證，因此系統更新不必重新登記：

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks
```

沒有加上 `--tpm2-with-pin=yes` 時，磁碟在開機時不需任何秘密就會解鎖，因此主機不能自動登入，而且必須在睡眠與休眠前鎖定工作階段。這類主機要記錄在 [`WORKAROUNDS.md`](WORKAROUNDS.md)。

initrd 依序嘗試 TPM2、FIDO2，最後是密碼。更換 Secure Boot 金鑰後 PCR 7 會改變：加上 `--wipe-slot=tpm2` 重新登記。保留密碼 slot 作為備援。

NixOS 安裝程式沒有以這些金鑰簽章；要用它救援時，在韌體裡關閉 Secure Boot 再開機。安裝中斷後簽章檢查失敗的主機，見 [lanzaboote 的疑難排解指南](https://github.com/nix-community/lanzaboote/blob/v1.2.0/docs/explanation/troubleshooting.md)。

## Updating

1. 更新輸入（`just update` 或 `just update-input <name>`），並依 [`AGENTS.md` 的〈Flake lock bumps〉](AGENTS.md#flake-lock-bumps)審查變更。
2. `just check` 必須通過。`just build` 會印出與執行中系統的套件差異；要讀過。
3. `just switch`。NixOS 上，核心或 initrd 有變動就重開機：`readlink -f /run/booted-system/kernel` 與 `readlink -f /nix/var/nix/profiles/system/kernel` 不同，代表需要重開機。
4. 出問題就回滾：NixOS 用開機選單或 `nixos-rebuild switch --rollback`，macOS 用 `darwin-rebuild --rollback`。

至少每週檢查一次更新；遭到實際利用的漏洞影響使用中的套件時立即檢查：[NixOS 安全公告](https://github.com/NixOS/nixpkgs/security/advisories)、[CISA 已知遭利用漏洞目錄](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)。

## If compromise is suspected

1. 中斷網路連線。
2. 從另一臺受信任的機器，輪替這臺主機持有的東西：帳號密碼、SSH 金鑰（從 [`vars/`](vars/) 與 GitHub 移除舊公鑰）、權杖，以及這臺主機能解密的 nix-secrets 機密。
3. 從這個 flake 重新安裝，而不是清理執行中的系統，並且只複製回檢查過的資料。

切換到較舊的世代無法復原入侵。
