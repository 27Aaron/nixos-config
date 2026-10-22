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
