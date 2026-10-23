# router

Proxmox 上的 NixOS 虛擬機。

## 硬體

| 項目 | 規格 |
|---|---|
| 平臺 | Proxmox VE 虛擬機（QEMU/KVM） |
| CPU | 4 vCPU |
| 記憶體 | 1 GB |
| 磁碟 | 20 GB（`/dev/sda`，ESP 256M） |

## 部署

在其他主機上建置，以 root 連入部署：

```bash
just deploy router root@<位址>
```
