# 主機

每臺機器一個目錄，目錄名稱就是主機名稱。`hosts/default.nix` 會自動探索這些目錄，新增主機不必改 flake。

```text
hosts/
└── nixos/<名稱>/    # NixOS 主機
```

## 主機目錄放什麼

- `default.nix`：這臺機器開了哪些功能，以及時區與 `stateVersion`。
- 其他 `.nix` 檔：只屬於這臺機器的硬體設定，依主題拆檔，例如磁碟、開機、電源。
- `README.md`：硬體規格與韌體備忘。

第二臺機器也用得到的設定，就做成 `modules/` 底下的模組。

## 新增主機

1. 建立 `hosts/nixos/<名稱>/default.nix`。
2. 在 `tests/security/nixos.nix` 的 `openPorts` 登記它的對外連接埠，見 `tests/README.md`。
3. 要遠端部署的主機，開啟 `services'.openssh.rootLogin`，之後以 `just deploy <名稱> root@<位址>` 部署。
4. 執行 `just build <名稱>` 確認能建置。
