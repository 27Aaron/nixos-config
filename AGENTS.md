# Agent Instructions

這個儲存庫是 NixOS 主機的 Nix flake。根目錄是 tmpfs：每次開機都會清空，只有登記到 [preservation](https://github.com/nix-community/preservation) 模組的狀態會留下，存放在以 LUKS 加密的 Btrfs 磁碟區上。設定要保持宣告式、可組合，並且在部署前就能驗證。

## Repository layout

| 路徑 | 內容 |
|---|---|
| [`flake.nix`](flake.nix) | 輸入與輸出 |
| [`lib/`](lib/) | 模組收集器與共用的 nixpak 沙箱模組 |
| [`hosts/`](hosts/) | 每臺主機一個目錄，自動探索 |
| [`modules/`](modules/) | 所有可重用的模組，依用途分目錄 |
| [`modules/core/`](modules/core/) | 每臺主機一律生效的模組，包括 shell、Git 等日常命令列工具 |
| [`modules/hardware/`](modules/hardware/)、[`modules/services/`](modules/services/) | 伺服器也可能用到的系統模組，可開關 |
| [`modules/dev/`](modules/dev/) | 開發環境、工具鏈與 AI agent，伺服器與桌面都能用，可開關 |
| [`modules/desktop/`](modules/desktop/)、[`modules/server/`](modules/server/) | 只有桌面或只有伺服器才用的模組，可開關 |
| [`tests/`](tests/) | `just check` 執行的 eval 測試 |
| [`vars/`](vars/) | 共用的非機密值 |
| [`SECURITY.md`](SECURITY.md) | 安全控制與對應測試、flake 輸入、機密與更新流程 |
| [`WORKAROUNDS.md`](WORKAROUNDS.md) | 暫時性的權宜做法、版本釘選與安全例外 |

`hosts/`、每臺主機的目錄、`modules/` 與 `tests/` 各有一份 `README.md`，說明什麼東西該放在那裡。新增檔案前先讀；變更讓它過時的話，一併更新。

## Host discovery

每個 `hosts/<name>/default.nix` 會成為 `nixosConfigurations.<name>`；目錄名稱以 `hostName` 傳給模組。`default.nix` 只放主機的功能開關、時區與 `stateVersion`，綁定這臺機器硬體的設定依主題拆成主機目錄下的其他檔案。第二臺機器也用得到的東西，就做成 [`modules/`](modules/) 底下的模組。

## Module conventions

- 模組由 [`lib/default.nix`](lib/default.nix) 的 `listModules` 自動收集；含 `default.nix` 的子目錄只透過該檔載入。
- 模組放在它能運作的最通用層級，順序見 [`modules/README.md`](modules/README.md)。
- 所有模組都是 NixOS 模組。使用者層的設定透過 `hm'`（`home-manager.users.<使用者>` 的別名）寫在同一個檔案裡，與該程式的系統設定和持久化放在一起，不另外分出 Home Manager 模組。
- `core/` 底下的模組一律生效，沒有 `enable` 選項。其他模組預設關閉，選項命名空間與 `enable` 開關比照相鄰的模組。
- 一個檔案只放一個程式或一件事。一個檔案放不下時，改成以 `default.nix` 為入口的目錄。

## Persistence

- 根目錄是 tmpfs，沒登記的路徑重開機後就不見了。模組把系統狀態登記在 `preservation'.os`、家目錄狀態登記在 `preservation'.user`，並以 `lib.mkIf config.hardware'.persistence.enable` 包起來。
- 狀態在產生它的模組裡登記。`~/.cache` 從不整個持久化，只列出值得保留的快取。
- 存放憑證、工作階段、金鑰或歷史紀錄的目錄要設 `mode = "0700"`。preservation 的預設是 `0755`，而且每次開機都會重新套用。
- 某個服務也可能由上游模組啟用時，要依它的最終狀態（例如 `config.hardware.bluetooth.enable`）決定是否持久化，而不是依這個模組的開關。
- 先寫暫存檔再呼叫 `rename()` 來更新檔案的程式（logrotate、zsh），在單一檔案的 bind mount 上會以 `EBUSY` 失敗；改成持久化上層目錄。
- machine-id 採用 bind mount 做法，並抑制 `systemd-machine-id-commit.service`；不要混用 symlink 做法的 commit 覆寫。

## Security

- [`SECURITY.md`](SECURITY.md) 記錄安全控制與對應測試、flake 輸入清單、執行期檢查，以及機密、更新與事件處理流程。新增或搬移控制、新增輸入，或把程式放進沙箱時，在同一個變更裡更新它。這個儲存庫是公開的：只寫控制做什麼、怎麼檢查，不寫個人設定細節，也不寫攻擊者用得上的弱點。
- 憑證與機密放在私人的 `nix-secrets` 儲存庫，透過 sops-nix 送進系統。`inputs.secrets` 會被複製到所有人可讀的 `/nix/store`，所以求值時只能讀其中的加密檔案，或本來就不敏感的檔案（例如 SSH 主機別名）。[`vars/`](vars/) 只放非機密值。
- 帳號密碼來自 nix-secrets 的 `users/password.yaml`，以 `neededForUsers` 在建立使用者之前解密；設定裡絕不放密碼或雜湊。每臺主機都靠 sops 做這件事，所以它是 core 模組。
- 主機以使用者的 `~/.ssh/id_ed25519` 解密（`sops.age.sshKeyPaths`；NixOS 主機直接讀 `/persistent` 上的那份），絕不另外放 age 金鑰檔。更換金鑰前先讀 [`SECURITY.md` 的〈Secrets〉](SECURITY.md#secrets)。
- 不要把使用者加進 `nix.settings.trusted-users`：受信任的使用者可以關閉簽章檢查、匯入任意 store 路徑，等同免密碼的 root。只有 `@wheel` 能連線到 daemon（`allowed-users`）。
- root 的 SSH 登入由各主機透過 `services'.openssh.rootLogin` 自行開啟，只用於遠端部署目標；其他主機只接受使用者的金鑰，再以 `sudo` 提權。root 仍保留授權金鑰，因為 initrd 的 SSH 解鎖要用。
- `security.sudo.execWheelOnly` 維持關閉：上游的 btrbk 模組以自己的使用者執行，並透過 sudo 規則呼叫 `btrfs`。
- [`core/kernel-hardening.nix`](modules/core/kernel-hardening.nix) 的核心基準使用 `lib.mkDefault`，主機以一般定義覆寫，絕不用 `mkForce`。有三項刻意不收緊：user namespace 保持開啟（Nix 建置沙箱需要）、`security.protectKernelImage` 保持關閉（它會停用休眠）、`kernel.kptr_restrict` 維持 1（dae 的 eBPF 函式庫會讀取 `/proc/kallsyms`）。主機需要 `core'.kernel.blockedModules` 裡的某個模組時（例如 IPsec VPN），就在那裡把它移除。
- 沙箱化的桌面程式使用 [`lib/nixpak/`](lib/nixpak/) 的 nixpak 模組，並列進 [`tests/security.nix`](tests/security.nix) 的 `sandboxedApps`。只綁定程式需要的路徑。絕不綁定整個 `$XDG_RUNTIME_DIR`：裡面有能啟動程式的 niri 控制 socket，以及 SSH 與 GPG agent。也絕不綁定未經過濾的 session bus：透過它，systemd 的使用者管理器能在沙箱外執行指令。以 FHS 打包的程式可以在 nixpak 裡執行，內層 FHS 環境看得到的東西受外層沙箱限制。
- 不 follow `nixpkgs` 的輸入帶有自己的 nixpkgs，只有在上游更新 lock 時才會拿到安全修正。目前只有 `fcitx5-vinput`，為了它的二進位快取（[WA-001](WORKAROUNDS.md#pins)）。

## Workarounds

每一個暫時性的權宜做法、版本釘選與已接受的安全例外，都要在引入它的同一個變更裡記錄到 [`WORKAROUNDS.md`](WORKAROUNDS.md)：取下一個 `WA-NNN` 編號、寫出具體的移除條件，並在程式碼旁的註解裡提到這個編號。條件達成時，刪除程式碼與該列，並在提交訊息裡寫出編號。nixpkgs、核心或 BIOS 更新後，重新檢查依賴它們的各列。

## Style and formatting

- 縮排用兩個空格，不用 tab，LF 換行，檔案結尾要有換行，行尾不留空白。
- 編輯 Nix 檔案後執行儲存庫的格式化工具 `nix fmt`。
- 只格式化這次任務改到的檔案，不要順手重新格式化無關的檔案。
- `README.md`、選項說明（option description）與提交訊息用英文。`AGENTS.md`、[`SECURITY.md`](SECURITY.md)、[`WORKAROUNDS.md`](WORKAROUNDS.md)、各目錄的 README 與 Nix 註解用臺灣慣用的繁體中文（設定、檔案、預設、支援）；前三份文件的標題維持英文，錨點連結才不會失效。Markdown 內文用全形標點；Nix 註解用半形 `,;:()` 搭配全形 `。、`。
- 註解說明「為什麼」：限制、上游的怪癖，或被否決的替代方案。不要重述下一行在做什麼，也不要加檔案開頭的說明註解。

## Validation

```bash
nix fmt
just check    # fmt --check、deadnix，以及 nix flake check --no-build --all-systems（包含 eval 測試）
just build    # 建置一臺主機；預設為本機主機名稱，也可以明確指定
```

影響範圍小的變更，可以只求值受影響的選項，例如 `nix eval .#nixosConfigurations.<name>.config.<option>`。變更主機探索、共用模組或 flake 輸入時，要建置每一臺受影響的主機。

[`tests/`](tests/) 的 eval 測試會在每臺主機上檢查上述安全規則，並維護對外連接埠、受信任二進位快取與私密持久化路徑的清單。變更刻意改動其中一項時（服務開了連接埠、新增快取、新增主機），在同一個變更裡更新 [`tests/security.nix`](tests/security.nix) 的預期值並說明理由。絕不只為了讓測試通過而放寬測試；見 [`tests/README.md`](tests/README.md)。

不應改變系統的重構或純註解變更，要在改動前後各記錄一次 toplevel derivation 並比對：

```bash
nix eval --raw .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath
nix run nixpkgs#nix-diff -- <old.drv> <new.drv>
```

## Deployment

部署一律手動，只在明確要求時執行；絕不把 switch 或遠端部署當成驗證的順帶動作。

```bash
just switch [target]                # 在本機套用主機設定
just deploy <target> root@<host>    # 遠端部署；目標需要 services'.openssh.rootLogin
```

與持久化相關的變更要重開機才生效，重開機之後再相信它們。

## Commit messages

使用 Conventional Commit 標題，scope 以路徑為準：

```text
type(scope): description
```

- 允許的類型有 `feat`、`fix`、`refactor`、`chore` 與 `WIP`。`WIP` 只用於明確標示為暫時的進行中快照。
- 提交標題用小寫英文，結尾不加句點。內文含專有名詞或完整句子時，照一般大小寫書寫，比較好讀。
- 標題連同 `type(scope): ` 不超過 50 個字元。GitHub 會截斷超過 72 個字元的標題，squash merge 還會再附加 ` (#123)`，50 個字元才有餘裕。標題只寫一個變更的結果，省略冠詞與贅字，清單與細節移到內文。
- 內文在 72 個字元處換行。
- pull request 標題會成為 squash merge 的提交標題，因此遵守相同規則。
- scope 反映變更的路徑或元件：主機專屬的變更用 `{host}` 或 `{host}/{service}`，共用模組用模組領域（`core`、`hardware`、`services`、`dev`、`desktop`、`server`、`modules`），flake 層級的檔案、[`lib/`](lib/) 與主機探索用 `flake`，文件用 `docs`。
- 描述變更的結果，而不是列出編輯過的檔案。

```text
refactor(home): bind flake packages by name instead of their package set   # 72 個字元，太長
refactor(home): bind flake packages directly                               # 44 個字元
```

### Flake lock bumps

更新 [`flake.lock`](flake.lock) 中的輸入時，要寫出上游改了什麼，不能只提 lock 檔或修訂雜湊。

1. 執行 `nix flake update <input>`，從輸出或 `git diff -- flake.lock` 記下新舊修訂。
2. 找出上游儲存庫，檢視這段範圍的變更。GitHub 上的輸入可用 compare API 或 `gh`：

   ```bash
   curl -s https://api.github.com/repos/<owner>/<repo>/compare/<old>...<new>
   # 或
   gh api repos/<owner>/<repo>/compare/<old>...<new>
   ```

3. 把更新當成一次供應鏈事件。對每個有變動的輸入，先查這個儲存庫從中用了什麼（見 [`SECURITY.md` 的輸入表](SECURITY.md#flake-inputs)）：
   - 提供 NixOS 或 Home Manager 模組的輸入（`home-manager`、`disko`、`preservation`、`sops-nix`），閱讀被匯入的模組檔案的變更，留意以下幾類：`nix.settings` 的 substituter、受信任金鑰或受信任使用者；啟用腳本、root 服務、sudo 或 polkit 規則；放寬擁有者或權限的 `environment.etc` 或 `home.file` 項目；`lib.mkForce` 覆寫；import-from-derivation。
   - 套件輸入要確認這裡用到的套件，變更與描述相符。
   - `just check` 會抓到新增的快取與對外連接埠；`just build` 會印出與執行中系統的套件差異。
4. 提交內文只保留有意義的變更，安全修正要明確點出。
5. 標題寫出輸入名稱，內文先寫簡短的修訂範圍，再接精簡的條列：

   ```text
   chore(flake): update home-manager input

   Update home-manager from f6c09b0b to 70386bb7 (2 commits):
   - summarize the meaningful change
   - summarize another relevant file or commit
   ```

新的第三方輸入若有發布版本，就釘在發行標籤或某個提交上，不追蹤分支；因暫時性原因而存在的釘選要記錄在 [`WORKAROUNDS.md`](WORKAROUNDS.md)。

一次更新多個輸入時，使用 `chore(flake): update flake inputs` 並在內文逐一列出，或拆成多個提交。上游變更紀錄或本機差異佐證不了的細節，不要寫進去。
