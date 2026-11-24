# hydra

Proxmox 上的 NixOS 虛擬機，當作家用實驗室的主機：以 magpie 提供 AI 閘道與網頁介面，並以 mihomo-lite 提供代理。

## 硬體

| 項目 | 規格 |
|---|---|
| 平臺 | Proxmox VE 虛擬機（QEMU/KVM，與 iris 同一部主機） |
| 磁碟 | `/dev/sda`（不加密，ESP 256M） |
| 網路 | `eth0` 靜態 `10.10.10.254/24`（閘道 `10.10.10.1`），不啟用 IPv6，名稱伺服器為閘道 `10.10.10.1` |

## 服務

- **magpie**：網頁介面在 `http://10.10.10.254`，環境金鑰由 sops 提供。
- **mihomo-lite**：混合代理埠 `7890` 與 zashboard（`9090`）對區網開放。設定檔只在首次部署時種下，之後直接編輯 `/etc/mihomo/config.yaml`。
- **node_exporter**：只對 tailnet 開放（`9100`）。

## 部署

在其他主機上建置，以 root 連入部署：

```bash
just deploy hydra root@10.10.10.254
```
