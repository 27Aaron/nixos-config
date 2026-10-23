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

## BIOS

BIOS 更新程式只有 Windows 的 `.EXE`。

- **下載：**[N.1.14MRO50](https://driver.mechrevo.com/d.mechrevo.com/driver/MECHREVO2024/WJ14X8845HS/GXxHXxxN114MRO50_CAP.EXE)
- **來源：**[w568w 的 WUJIE 14XA 逆向筆記](https://gist.github.com/w568w/b2fc5f9d1f4dff13efe751abec27b396?permalink_comment_id=6147538#gistcomment-6147538)

## Secure Boot 與磁碟解鎖

以 lanzaboote 開機，簽章用的是自己產生的金鑰。設定步驟見 [SECURITY.md 的 Secure Boot](../../../SECURITY.md#secure-boot)。

- 只登記自己的金鑰，不含 Microsoft 金鑰：TPM 事件記錄共 84 筆，其中沒有 `EV_EFI_BOOT_SERVICES_DRIVER`，表示開機時不會載入外部 Option ROM；內顯的 GOP 包在 BIOS 裡。
- 之後若要透過 USB4 接外接顯卡，並需要它在開機選單或 BIOS 階段就有畫面，要改用 `sbctl enroll-keys --microsoft` 重新登記。進入 Linux 後不受影響。

磁碟以 TPM2 解鎖，綁定 PCR 7，不設 PIN，所以開機時不必輸入任何東西（例外紀錄見 WORKAROUNDS.md 的 WA-023）。安全性改由以下幾點維持：

- Secure Boot：換掉 kernel 或 initrd、關閉 Secure Boot，或從其他開機碟開機，都會讓 PCR 7 改變，TPM 就不會交出金鑰。
- 不自動登入：開機後停在 tuigreet，必須輸入帳號密碼。
- 睡眠前鎖定：Noctalia 的 `[lockscreen].lock_before_suspend` 預設開啟，從睡眠或休眠恢復後都是鎖定畫面。這個設定由 Noctalia 介面管理，不在 Nix 裡，關掉它就違反了 WA-023 的前提。

LUKS slot 只有 `0 password` 與 `1 tpm2`。清除 CMOS 或重設 BIOS 可能清空 fTPM，更換 Secure Boot 金鑰也會改變 PCR 7；遇到這些情況，用 LUKS 密碼開機後重新登記 TPM2，指令見 SECURITY.md。
