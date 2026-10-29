# elaina

Beelink SER6 Pro VEST 迷你主機，當作沒有螢幕的家用伺服器。

## 硬體

| 項目 | 規格 |
|---|---|
| 型號 | Beelink SER6 Pro VEST |
| CPU | AMD Ryzen 7 7735HS |
| 記憶體 | 64 GB DDR5 |
| 磁碟 | 2 TB NVMe，UncertainTruth LX700（ESP 1G，LUKS，TPM2 解鎖） |

## Secure Boot 與磁碟解鎖

以 lanzaboote 開機，簽章用的是自己產生的金鑰。設定步驟見 [SECURITY.md 的 Secure Boot](../../SECURITY.md#secure-boot)。

- 出廠時韌體就在 Setup Mode（沒有 PK、KEK、db，dbx 保留），所以不必在 BIOS 清除金鑰。
- 只登記自己的金鑰，不含 Microsoft 金鑰：TPM 事件紀錄共 125 筆，其中沒有 `EV_EFI_BOOT_SERVICES_DRIVER`，表示開機時不會載入外部 option ROM；唯一的顯示卡是內顯，GOP 包在 BIOS 裡。

磁碟以 TPM2 解鎖（綁定 PCR 7，不設 PIN），開機不需要任何秘密，例外紀錄見 [WORKAROUNDS.md 的 WA-022](../../WORKAROUNDS.md#security-exceptions)。

TPM2 失效時（清除 CMOS、重設 BIOS、更換 Secure Boot 金鑰），要接上鍵盤輸入 LUKS 密碼開機，再重新登記。這臺沒有啟用 initrd SSH，無法從遠端解鎖。
