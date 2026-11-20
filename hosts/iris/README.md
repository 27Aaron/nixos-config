# iris

Proxmox 上的 NixOS 虛擬機，擔任區網的 DNS 伺服器：AdGuard Home 對區網監聽 53，過濾廣告後轉給本機的 mosdns 做中國/國外分流。

## 硬體

| 項目 | 規格 |
|---|---|
| 平臺 | Proxmox VE 虛擬機（QEMU/KVM，與 hydra 同一部主機） |
| 磁碟 | `/dev/sda`（SATA，ESP 256M，LUKS 經 clevis 解鎖） |
| 網路 | `eth0` 靜態 `10.10.10.9/24`（閘道 `10.10.10.1`），IPv6 由上游 DHCPv6 派發（比照 janus） |

## 部署

在其他主機上建置，以 root 連入部署：

```bash
just deploy iris root@10.10.10.9
```

初次啟動後照 `modules/services/network/adguardhome.nix` 開頭的清單完成 AdGuard Home 的精靈頁設定。
