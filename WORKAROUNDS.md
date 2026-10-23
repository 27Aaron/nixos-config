# Workarounds

暫時性的權宜做法、版本釘選與已接受的安全例外，每一項都附上可以移除的條件。沒有這份清單，上游修好之後本機的權宜做法會被遺留下來，也沒人記得它為什麼在那裡。

## How to use

- **新增：**引入權宜做法、釘選或例外的變更，在同一個提交裡於此新增一列，寫上具體的移除條件，並在程式碼旁的註解裡提到編號。
- **移除：**條件達成後，刪除程式碼與該列，並在提交訊息裡提到編號。
- **檢查：**nixpkgs、核心或 BIOS 更新後，檢查條件依賴它們的各列。

`git grep WA-` 會找出每一列以及它對應的程式碼。

## Pins

| 編號 | 內容與位置 | 原因 | 移除條件 | 新增日期 |
|---|---|---|---|---|
| WA-001 | `fcitx5-vinput` 釘在標籤 `v2.4.2`，且不 follow `nixpkgs`：`flake.nix`，由 `modules/nixos/desktop/input-method/vinput.nix` 使用 | `fcitx5-vinput.cachix.org` 的二進位檔以上游自己的 lock 建置；follow `nixpkgs` 會在本機編譯 sherpa-onnx。代價是多一份只有在上游更新 lock 時才會拿到安全修正的 nixpkgs，以及一個受信任的二進位快取。 | 套件進入 nixpkgs，或本機建置變得可以接受；屆時改為 follow `nixpkgs`，並從 `modules/nixos/desktop/input-method/vinput.nix` 與 `tests/security/shared.nix` 移除快取。在那之前，標籤要刻意升級。 | 2026-10-18 (#152) |

## Workarounds

| 編號 | 內容與位置 | 原因 | 移除條件 | 新增日期 |
|---|---|---|---|---|
| WA-002 | 休眠後以 `lid_init_state=open` 重新綁定 `acpi-button`：`hosts/nixos/river/power.nix` | `HibernateMode=shutdown` 會切斷電源，所以打開上蓋不會送出事件，而 `_LID` 會從映像還原成關閉狀態；logind 於是一再重新進入睡眠。 | 移除這個 hook 後，從休眠恢復不再重新進入睡眠。BIOS 或核心更新後檢查。 | 2026-10-22 (#177) |
| WA-003 | 恢復後重新綁定 I2C 觸控板（`UNIW0001`、`i2c_hid_acpi`）：`hosts/nixos/river/power.nix` | 休眠後觸控板不會重新列舉。 | 不重新綁定，恢復後觸控板也能運作。BIOS 或核心更新後檢查。 | 2026-10-22 (#176) |
| WA-004 | `boot.consoleLogLevel = 3`：`hosts/nixos/river/hardware.nix` | 韌體的 ACPI 錯誤會洗滿開機畫面；它們仍保留在 journal 裡。 | BIOS 更新修好 ACPI 表。 | 2026-10-18 (#148) |
| WA-005 | `programs.ssh.systemd-ssh-proxy.enable = false`：`modules/nixos/base/core/ssh-client.nix` | 被 include 的 systemd drop-in 在 store 裡的擁有者是 `nobody`；OpenSSH 10 因此拒絕整份 `ssh_config`，每個 `ssh` 與 `git` 呼叫都會失敗。 | nixpkgs 或 OpenSSH 不再因這個 include 失敗。 | 2026-10-20 (#164) |
| WA-006 | `~/.ssh/config` 在啟用時複製，而不是由 `home.file` 建立連結：`modules/home/base/cli/ssh.nix` | OpenSSH 10 要求 `~/.ssh/config` 由使用者擁有；Home Manager 的連結指向 root 擁有的 store 檔案。 | Home Manager 或 OpenSSH 接受 store 連結。 | 2026-10-19 (#157) |
| WA-007 | 在 Nagram 的 FHS 環境加入 `xkeyboard-config`：`modules/home/nixos/gui/nagram.nix` | 上游二進位檔內附的 libxkbcommon 只搜尋 `/usr/share/X11/xkb`，找不到就會在 Wayland callback 裡 segfault。 | 上游不再內附 libxkbcommon，或 nixpkgs 打包了 Nagram。 | 2026-10-16 (#124) |
| WA-008 | keyd 把 `rightcontrol` 對應到它自己：`hosts/nixos/river/keyboard.nix` | keyd 預設會把右 Ctrl 併入左 Ctrl。 | keyd 會區分右手的修飾鍵。 | 2026-10-19 (#160) |
| WA-009 | dae 設定由強制的 `ExecStartPre` 組合到 `/etc/dae`：`modules/nixos/base/services/dae.nix` | 上游模組只複製入口檔，遺漏被 include 的 `config.d`；dae 也拒絕其他人可讀的 include 檔案，因此不能放在 store。 | nixpkgs 的 dae 模組支援含 include 的設定目錄。 | 2026-10-17 (#131) |
| WA-010 | 空的 `tmpfiles.d/lastlog2-tmpfiles.conf`：`modules/nixos/base/hardware/persistence.nix` | 它的規則與持久化的 `/var/lib/lastlog` 衝突。 | NixOS 或 preservation 不再衝突；確認移除覆寫後開機沒有 tmpfiles 錯誤。 | 2026-10-16 (#125) |
| WA-011 | 空的 `plugdev` 群組：`modules/nixos/base/hardware/yubikey.nix` | libfido2 的 udev 規則寫了 `GROUP="plugdev"`，而 NixOS 沒有這個群組；每次開機都會記錄數百則解析錯誤。存取權本來就由 `TAG+="uaccess"` 授予。 | nixpkgs 裡的 libfido2 規則拿掉 `plugdev`。 | 2026-10-20 (#163) |
| WA-012 | 為 `vinput-daemon` 設定 `VINPUT_ASR_LIBOPUS_PATH`：`modules/nixos/desktop/input-method/vinput.nix` | 命令列辨識器忽略 `LD_LIBRARY_PATH`，找不到 libopus 就會結束。 | 上游不需要這個變數也能找到 libopus。 | 2026-10-18 (#152) |

## Security exceptions

刻意偏離 `AGENTS.md` 與 `SECURITY.md` 規則的地方，以及需要在這個儲存庫以外處理的缺口。

| 編號 | 內容與位置 | 原因 | 移除條件 | 新增日期 |
|---|---|---|---|---|
| WA-013 | `kernel.kptr_restrict` 維持 1 而不是 2：`modules/nixos/base/core/kernel-hardening.nix` | dae 的 eBPF 函式庫會讀取 `/proc/kallsyms`，設為 2 時連 root 看到的都是零。 | `sudo sysctl kernel.kptr_restrict=2 && sudo systemctl restart dae` 後 dae 仍正常運作；屆時調高並更新測試。 | 2026-10-22 (#191) |
| WA-016 | sops 以使用者自己的 SSH 金鑰解密，而不是只有 root 能讀的金鑰，而且所有機密共用同一組收件人：`modules/nixos/base/core/sops.nix`、`modules/darwin/core/sops.nix`、nix-secrets 的 `.sops.yaml` | 為了簡單而選擇。 | 整理 nix-secrets 時重新檢討。 | 2026-10-22 |
| WA-021 | 擁有者在 `gamemode` 群組裡：`modules/nixos/desktop/game/gamemode.nix` | GameMode 的調整輔助程式需要它。 | 不再使用 GameMode，或它不再需要整個群組的授權。 | 2026-10-22 |
| WA-022 | elaina 的 TPM2 金鑰登記時沒有 PIN；磁碟在開機時不需任何秘密就會解鎖：`hosts/nixos/elaina/storage.nix`，登記指令在 `modules/nixos/base/hardware/disko.nix` | 這臺主機沒有鍵盤。它不執行桌面工作階段，而 Secure Boot 會讓遭竄改的開機鏈拿不到金鑰。 | 主機接上鍵盤時重新檢討。 | 2026-10-23 |
| WA-023 | river 的 TPM2 金鑰登記時沒有 PIN；磁碟在開機時不需任何秘密就會解鎖：`hosts/nixos/river/storage.nix`，登記指令在 `modules/nixos/base/hardware/disko.nix` | 為了方便而選擇。Secure Boot 會讓遭竄改的開機鏈拿不到金鑰，greetd 會要求帳號密碼，Noctalia 也會在睡眠與休眠前鎖定工作階段（`[lockscreen].lock_before_suspend`，預設為 `true`，在它的 UI 裡設定而非在 Nix 裡）。 | river 再次改回自動登入，或不再於睡眠前鎖定時重新檢討。 | 2026-10-23 |
