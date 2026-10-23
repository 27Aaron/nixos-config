# 測試

`just check` 會執行這裡的 eval 測試：求值每臺主機的設定，與預期值比對，不建置、也不啟用系統。NixOS 主機的測試在 `checks.x86_64-linux`，nix-darwin 主機的在 `checks.aarch64-darwin`；加上 `--all-systems`，Linux 上也會求值後者。

單獨執行：

```bash
nix build --no-link .#checks.x86_64-linux.eval-tests
nix eval --raw .#checks.aarch64-darwin.eval-tests.text
```

## 案例怎麼寫

每個案例是一個函式，接收一臺主機的 `nixosSystem` 或 `darwinSystem` 結果，回傳 `expr`（實際值）與 `expected`（預期值）：

```nix
nix-trust =
  { config, ... }:
  {
    expr = config.nix.settings.trusted-users;
    expected = [ "root" ];
  };
```

- 案例依平臺分檔，新增主機時自動涵蓋：
  - `security/shared.nix`：每一臺主機，例如 Nix 信任設定、快取、Home Manager 的程式。
  - `security/nixos.nix`：只有 NixOS 主機，例如 SSH、防火牆、核心、持久化。
  - `security/darwin.nix`：只有 nix-darwin 主機。
- 只對部分主機有意義的設定，用 `lib.optionalAttrs` 讓實際值與預期值同時變成空集合。
- 預期值寫成具體的值，或只依主機宣告的意圖推導（例如 `services'.openssh.rootLogin`）。不要照抄被測模組的實作，否則模組寫錯時，測試也會跟著錯。
- 失敗訊息會列出主機、案例名稱、預期值與實際值。

## 清單

`security/` 各檔開頭的清單記錄的是安全決定。改動清單就等於做了一次決定，要在同一個變更裡說明理由：

- `openPorts`（`nixos.nix`）：各主機對外開放的連接埠。服務新開了連接埠，或新增 NixOS 主機，都要在這裡登記。
- `caches`（`shared.nix`）：信任的二進位快取與簽章金鑰。每一個都能把任意 store 路徑送進系統。
- `privateDirs`、`privateFiles`、`privateSystemDirs`（`nixos.nix`）：一旦持久化，就必須只有擁有者能讀的路徑。
- `kernelSysctl`、`blockedModules`（`nixos.nix`）：每臺主機的核心參數基準與禁止載入的模組。
- `sandboxedApps`（`shared.nix`）：只能以 nixpak 沙箱版本安裝的程式。
