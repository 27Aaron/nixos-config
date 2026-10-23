# 主機

每臺機器一個目錄，目錄名就是主機名，由 `hosts/default.nix` 自動探索，新增主機不必改 flake。

```text
hosts/
├── nixos/<名稱>/    # NixOS 主機
└── darwin/          # nix-darwin 主機,預留
```

## 主機目錄放什麼

- `default.nix`：這臺機器開了哪些功能、時區、`stateVersion`。
- 其他 `.nix` 檔：只屬於這臺機器的硬體設定，依主題拆檔，例如磁碟、開機、電源。
- `README.md`：硬體規格與韌體備忘。

能被第二臺機器用到的設定，應該做成 `modules/` 底下的模組。

## 新增主機

1. 建立 `hosts/nixos/<名稱>/default.nix`。
2. 需要遠端部署的主機，開啟 `services'.openssh.rootLogin`，之後以 `just deploy <名稱> root@<位址>` 部署。
3. 執行 `just build <名稱>` 確認能建置。

第一臺 Mac 需要先在 flake 加入 `nix-darwin` 輸入，並在 `hosts/default.nix` 接上 `darwinConfigurations`。
