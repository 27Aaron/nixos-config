# 模块目录结构

本目录下放着所有可复用的 NixOS、nix-darwin 与 Home Manager 模块。`hosts/<name>/` 下的主机配置保持
为一个薄选择器：它只负责打开能力开关，以及保留属于这台机器自己的东西。

这套结构的意义在于：**文件所在的位置，说明了它被允许碰什么**。`nixos/` 下的文件设系统选项，
`home/` 下的文件设 Home Manager 选项。角色目录再进一步说明这些设置是给谁的：`nixos/base/` 面向
每一台 NixOS，`nixos/desktop/` 面向有屏幕的机器，`nixos/server/` 面向无头机器。

最后这层是**由各模块的 enable 开关维持的约定，而不是由 import 机制强制的**——`modules/default.nix`
会把整棵树喂给每一台主机，所以 `nixos/desktop/` 里的模块在服务器上同样会被求值。因此它必须在主机
打开它之前保持惰性。

## 三个问题决定位置

按顺序问，先能回答的那个就定了。

1. **哪个平台？** `base/` 两边通用，`nixos/` 只给 NixOS，`darwin/` 只给 nix-darwin。
2. **系统还是用户？** `modules/nixos/` 与 `modules/darwin/` 设系统选项（`boot.*`、`services.*`、
   `users.*`）；`modules/home/` 设 Home Manager 选项（`programs.*`、`home.*`、`xdg.*`）。
3. **哪个角色、哪种形态？** 系统模块按主机角色分（`base`、`desktop`、`server`）；Home Manager
   模块按程序自己怎么画分（`core`、`tui`、`gui`）。

平台在两边都是最外层的切分，所以两棵树是镜像的：

```text
modules/                          modules/home/
├── base/                         ├── base/
├── nixos/                        │   ├── core/
│   ├── base/                     │   ├── tui/
│   ├── desktop/                  │   └── gui/
│   └── server/                   ├── nixos/
└── darwin/                       └── darwin/
```

## 目录结构

```text
modules/
├── default.nix            # 遍历本树，定义 user' 与 hm' 别名
├── base/                  # 预留：NixOS 与 nix-darwin 完全相同的设置
├── darwin/                # 预留：nix-darwin 系统模块
├── nixos/
│   ├── base/              # 每一台 NixOS
│   │   ├── core/          #   身份、用户，以及管理面
│   │   ├── hardware/      #   这台机器物理上有什么，含 boot/
│   │   └── services/      #   后台守护进程
│   ├── desktop/           # 谁来登录，以及会话长什么样
│   └── server/            # 预留：无头主机
└── home/                  # Home Manager
    ├── base/              #   两个平台都跑
    │   ├── core/          #     自己不画界面
    │   ├── tui/           #     接管终端
    │   └── gui/           #     开一个窗口
    ├── nixos/             #   预留：只有 NixOS 需要的 Home Manager 设置
    └── darwin/            #   预留：只有 macOS 需要的 Home Manager 设置
```

上面的目录都已建好，文件也已经搬进去了，过程记在[迁移记录](#迁移记录)。新建的每个目录原本带一个
`.gitkeep`，因为 Git 不跟踪空目录；放入真实模块时已经删掉。仍然留着的四个——`base/`、`darwin/`、
`nixos/server/`、`home/darwin/`——要等到第二个平台或第一台无头主机真的需要它们。

## nixos/base —— 每一台 NixOS

"Base" 的意思是**任何一台 NixOS 都可能用到**，不是**每一台都必须打开**；开关写在
`hosts/<name>/default.nix` 里。三个子目录回答不同的问题，所以一个文件很少有两个都说得通的位置。

| 目录        | 它回答的问题                   |
| ----------- | ------------------------------ |
| `core/`     | 这台机器是谁，以及怎么管理它？ |
| `hardware/` | 这台机器物理上有哪些硬件？     |
| `services/` | 哪个守护进程在后台运行？       |

按目前的内容就是：

- **`core/`** —— `host.nix`（用户、主机名、默认时区）、`fish.nix`、`i18n.nix`、`nix.nix`、
  `sops.nix`、`firewall.nix`、`logging.nix`、`yubikey.nix`。
- **`hardware/`** —— `disko.nix`、`persistence.nix`、`boot/systemd-boot.nix`、`boot/initrd-ssh.nix`、
  `amdgpu.nix`、`bluetooth.nix`、`brightness.nix`。
- **`services/`** —— `openssh.nix`、`networkmanager.nix`、`fail2ban.nix`、`logrotate.nix`、`zram.nix`、
  `btrbk.nix`、`btrfs-scrub.nix`、`smartd.nix`、`vnstat.nix`、`trash.nix`、`dae.nix`、`keyd.nix`、
  `pipewire.nix`、`upower.nix`、`power-profiles-daemon.nix`。

`hardware/` 放在 `base/` 下面而不是与 `desktop/` 平级，是因为硬件与角色正交：服务器有磁盘，笔记本
也有磁盘，两边都可能想打开同一个 `hardware'.disko`。服务器只是不打开 `hardware'.bluetooth` 而已。

每个目录对应且只对应一个选项命名空间，这正是整棵树可预测的原因：

| 目录                  | 命名空间      |
| --------------------- | ------------- |
| `nixos/base/core`     | `core'.*`     |
| `nixos/base/hardware` | `hardware'.*` |
| `nixos/base/services` | `services'.*` |
| `nixos/desktop`       | `desktop'.*`  |

## nixos/desktop —— 有屏幕的主机

只在这台机器前面坐着人时才有意义的东西：登录管理器（`greetd.nix`）、合成器（`niri.nix`）、桌面
外壳（`noctalia.nix`）、输入法（`fcitx5.nix`、`vinput.nix`）、系统字体（`fonts.nix`）、文件管理器
（`file-manager.nix`）。

判断法是：「在无头服务器上打开它，是毫无意义，还是只是没用上？」**毫无意义**的放 `desktop/`，
**只是没用上**的放 `base/`。

这就是为什么 `pipewire`、`upower`、`power-profiles-daemon` 与 `keyd` 目前仍然留在
`nixos/base/services`，尽管它们确实是桌面机的关注点：把它们移过来意味着要把 `services'.pipewire`
改名成 `desktop'.pipewire`，那是**重构主机配置**，不是移动文件。请当成独立的一次改动、单独一个
commit 来做。

## nixos/server —— 无头主机

预留。只属于服务器的设置放这里，例如虚拟机客户机支持、远程构建机，或者绝不能跑在工作站上的服务。
在这个目录还是空的时候，一台服务器主机只 import `nixos/base`，别的都不引。

## home —— Home Manager

`home/base/` 在 NixOS 与 macOS 上都能跑；`home/nixos/` 与 `home/darwin/` 放只有单平台才需要的东西。
`base/` 下面的三个桶只用一个标准区分：**这个程序画什么？**

| 桶      | 标准               |
| ------- | ------------------ |
| `core/` | 自己不画任何界面   |
| `tui/`  | 运行时接管整个终端 |
| `gui/`  | 开一个窗口         |

按目前的内容就是：

- **`base/core/`** —— `shell.nix`（fish、zsh、提示符、别名）、`git.nix`、`development.nix`
  （direnv、mise、uv）、`packages.nix`（fd、ripgrep、jq、curl、fastfetch、duf、dust）。
- **`base/tui/`** —— `agents/`（claude-code、dsh）、`git/lazygit.nix`、`monitoring.nix`（btop、ncdu、
  nload）；以后还有 `yazi`、`nvim`。
- **`base/gui/`** —— `terminal/`（kitty）、`browsers/`（chrome、firefox）、`editors/`（vscode、zed）、
  `agents/`（claude-desktop、dsh-desktop）、`nagram.nix`、`seahorse.nix`、`pointer-cursor.nix`、
  `theme.nix`、`mime-apps.nix`、`user-dirs.nix`。
- **`home/nixos/`** —— 目前只有 `magpie.nix`，因为托盘程序注册 `systemd.user.services`。

### 接线的两个层次

`modules/home/` 在根上保留一个 `default.nix`，正是这个文件让日后的平台分家成为可能。
`modules/default.nix` 遇到带 `default.nix` 的目录就停止递归，所以：

- `modules/home/default.nix` 是**平台入口**：NixOS 这边 import `./base` 和 `./nixos`。darwin 入口
  则 import `./base` 和 `./darwin`。遍历永远进不到 `modules/home/` 内部，这就是 `home/nixos/`
  不可能漏进 macOS 主机的原因。
- `modules/home/base/default.nix` 是**共用清单**：放每个用户都要的设置、宣告 `persist'` 选项，并
  列出要 import 的桶与文件。`base/` 下面任何模块的移动或新增，改的就是这个文件。

把根上的 `default.nix` 删掉，两层就会塌成一层：遍历会递归进 `modules/home/`，把 `base/`、`nixos/`
和 `darwin/` 下的每个文件都 import 进每一台主机。**留着它。**

### 普通终端到底放哪

这是最容易放错的一个，因为终端模拟器既是终端、又是窗口。按它画什么来分：

- **kitty → `base/gui/terminal/`**。它是一个图形程序，只是刚好用来渲染文字。在一个没有其他终端的
  会话里它照样起得来，因为**它就是那个终端**。
- **btop、ncdu、nload、lazygit、nvim → `base/tui/`**。它们需要一个已经存在的终端，没有就根本起不来。
- **fd、ripgrep、jq、fastfetch、duf、dust → `base/core/`**。自己没有画面：读入、输出、退出。

一个容易混淆的边界是 `ncdu` 与 `duf`：名字和用途几乎一样，但 `duf` 印出表格就退回，`ncdu` 停在
ncurses 界面里等按键。**判断依据是「它退不退出」，不是「它属于哪个领域」**：同一类工具可以分属两个
桶，只要一个交互、一个不交互。

大家第一个想到的名字是 "cli"，但那是错的切分轴：kitty、btop、fd 全都是命令行程序，所以一个
`cli/` 桶必须同时装下这三类。真正能把它们分开的问题是：**程序运行时是否占据屏幕**——完全不占、
占满、还是占一个自己的窗口。

`cli` 仍然值得作为一个 `core/` 下的子目录存在，含义收窄成「只装命令，不装任何配置」。等
`packages.nix` 长到需要拆分时，按领域分——`base/core/cli/search.nix`、`base/core/cli/network.nix`、
`base/core/cli/disk.nix`——而不是把 `cli` 提升成与 `tui/`、`gui/` 平级的第四个桶。目前还没拆，
因为 20 个包放进一个文件还看得过来。

`core/` 内部还有一层区分值得保留：`shell.nix`、`git.nix`、`development.nix` 是**配置**一个工具，
因此会改变它的行为——你落进哪个 shell、commit 上署谁的名、哪些工具链会被激活；`packages.nix` 只是
**安装**程序，就是一份纯粹的 `home.packages` 列表。

### 为什么 Home Manager 这边也要分平台

Home Manager 天生跨平台，所以绝大多数设置落在 `base/` 里就再也不用动了。只有两种情况必须给它们
一个专门的位置：

- **只在单平台存在的模块。** nix-darwin 的 Home Manager 那边多出 NixOS 没有的选项
  （`targets.darwin-defaults`、launchd agents、`homebrew.*`），而 NixOS 这边多出 `systemd.user.*`。
  `programs.magpie` 已经在用 `systemd.user.services`，所以它原样搬到 macOS 是跑不通的。
- **只在单平台打包的包。** 一个在 aarch64-darwin 上构建不出来的 `home.packages` 条目会让求值失败，
  连带整个 darwin 主机一起挂掉。

`base/` 是默认，平台目录是例外：**当一个文件确实是带着某个平台写的，再放过去，不要为了对称提前
拆散。** 一个 `base/` 里的文件如果长出了 `lib.mkIf pkgs.stdenv.isDarwin`，那说明它想被拆分，而不是
需要再加一个条件判断。

### 桌面这条边界横跨两棵树

`home/base/gui` 与 `nixos/desktop` 都跟桌面有关，由上面的第二个问题决定一个设置归谁。要在每个
用户层面安装和配置一个程序，就放 Home Manager（`programs.kitty`、`programs.zed-editor`、
`home.packages`）；`nixos/desktop` 只留给那些**必须在任何用户登录之前就存在**、或者**需要 root**
的东西：显示管理器、udev 规则、系统级字体、会话服务。

拿不准时先试 Home Manager——它让系统闭包更小，也让配置能搬到非 NixOS 的机器上。

## import 是怎么工作的

`modules/default.nix` 遍历这棵树，import 它找到的每一个 `.nix` 文件。带自己 `default.nix` 的目录
会被当作一个整体 import，而不再向下遍历，这就是为什么 `modules/home` 是唯一需要显式 import 清单
的子树。

需要知道的几个后果：

- `modules/nixos/`、`modules/darwin/`、`modules/base/` 下的文件不需要登记：放进去就够了。
- `modules/home/` 下的文件需要登记——加到 `modules/home/base/default.nix` 的
  `home-manager.users.<name>.imports` 列表里。任何嵌套目录一旦有了自己的 `default.nix`，同理。
- `modules/` 以下的一切都会到达每一台 NixOS，所以模块必须默认惰性：用 `lib.mkEnableOption` 宣告
  `options.<namespace>.enable`，并用 `lib.mkIf` 把内容包起来。
- 命名空间取决于**拥有这个关注点的目录**，而不是文件名。
- Home Manager 的运行时状态通过 `persist'.directories` 与 `persist'.files` 上报，
  `nixos/base/hardware/persistence.nix` 会把它们并进 `preservation'.user`。在 tmpfs 根目录下，
  没有登记在那里的东西重启后就没了。

**在第一个 darwin 模块落地之前**，`modules/default.nix` 必须停止把整棵平台树当成一团来遍历。
nix-darwin 没有 `services.greetd`，也没有 `boot.loader.systemd-boot`，所以一个仅仅是「没被打开」的
NixOS 模块，一旦同一个入口也去喂 darwin 主机，就不再是无害的了。到那时把它拆开：

- NixOS 入口 import `modules/base` + `modules/nixos` + `modules/home/base` + `modules/home/nixos`；
- darwin 入口 import `modules/base` + `modules/darwin` + `modules/home/base` +
  `modules/home/darwin`。

这条是给未来的自己看的。`modules/home/base/` 之所以要自带 `default.nix`，就是为了让两个平台能
各自 import 它，而不必把整个 `home/` 一起拉进来。

## 新增一个模块

1. 用上面三个问题确定桶。**新建文件，不要新建顶层目录。**
2. 宣告 `options.<namespace>.<name>.enable = lib.mkEnableOption "…";`，把内容放进
   `config = lib.mkIf cfg.enable { … };`。
3. 程序重启后必须留下的东西，用 `persist'.directories` 或 `persist'.files` 登记。
4. 文件在 `modules/home/base/` 下就加到 `modules/home/base/default.nix`；在 `modules/home/nixos/`
   下就加到 `modules/home/default.nix`。NixOS 模块不需要登记。
5. 在需要它的主机上打开：`hardware'.bluetooth.enable = true;`。
6. 跑 `nix fmt` 和 `just check`。

## 迁移记录

文件已经搬完，`modules/{core,desktop,hardware,services,home}` 不再存在。这一步只动位置，**选项名一个
都没改**，所以 `hosts/<name>/default.nix` 在迁移前后都能照常工作。验证方式是拿迁移前的 commit 对比：
系统包列表 202 个、Home Manager 包列表、以及 66 个持久化目录加 4 个文件，全部完全一致。

分四次 commit 完成，每次都可以单独回退：

1. 系统模块搬进 `nixos/{base,desktop}`；
2. `home` 拆成平台入口与共用清单两层，模块搬进三桶，`llm` 按软件拆分；
3. `btop`、`fastfetch` 从 `core` 移到 `tui`；
4. 修正三个放错位置的模块（见下）。

### 拆分过程中修正的问题

| 问题                                   | 处理                                               |
| -------------------------------------- | -------------------------------------------------- |
| `llm/default.nix` 一个文件管四个 agent | 拆成四个文件，各自管自己的包与持久化               |
| `cursor.nix` 其实不是 Cursor 编辑器    | 改名 `gui/pointer-cursor.nix`，它只设 XCursor 主题 |
| `lazygit` 混在 `core/git.nix`          | 独立成 `tui/git/lazygit.nix`                       |
| `ncdu`、`nload` 是 ncurses 交互界面    | 移到 `tui/monitoring.nix`                          |
| `apps.nix` 是杂物袋                    | 拆成 `gui/nagram.nix` 与 `gui/seahorse.nix`        |
| `cli/tools.nix` 名不副实               | 改名 `core/packages.nix`，只留「印完就退出」的工具 |

`fastfetch`、`duf`、`dust` 留在 `core`：它们印一次结果就退出，不接管画面，符合上面的标准。

### 仍然待处理的

- **`shell.nix` 同时启用 fish 与 zsh**，但系统侧 `nixos/base/core/fish.nix` 已经把 fish 定为登录
  shell，zsh 实际上只在 `.zsh_history` 被持久化时才会用到。要么删掉 zsh，要么在注释里说明它什么时候
  用得上。
- **`zed.nix` 的 `extraPackages`** 装了 14 个语言工具链，与 `core/development.nix` 的 mise/uv 构成两
  套工具链来源。目前只进 Zed 的 PATH，有注释说明，暂时保留；如果哪天两边版本打架，再抽出去。
- **`magpie.nix` 放在 `home/nixos/`**，因为它注册 `systemd.user.services`。文件名看不出它是 GUI 托
  盘程序，可以考虑改名 `magpie-tray.nix`。
- **`tmpfs` 根目录下 `~/.cache` 不整体持久化**是刻意的；各模块只登记真正需要跨重启的单项。

## Darwin 什么时候来

`modules/darwin/` 预留给 nix-darwin 系统模块：system defaults、Homebrew、macOS 安全设置，以及与
NixOS 不同的那些 `nix.settings`。`modules/home/darwin/` 是它在 Home Manager 那边的对应物。在此之前
两者各自只有一个 `.gitkeep`。第一个真实模块落地前，flake 里有三件事要改：

- 在 `flake.nix` 里加上 `nix-darwin` input；
- 加一个 `darwinConfigurations` 输出，按 `hosts/<name>` 来构建，就像今天 `hosts/default.nix` 构建
  `nixosConfigurations` 那样。`hosts/default.nix` 现在调用的是 `lib.nixosSystem`，所以它照现状是
  构建不出 darwin 主机的；
- 按平台拆分 `modules/default.nix`（见 [import 是怎么工作的](#import-是怎么工作的)），并让两个入口
  各自指向 `modules/base` 加自己的平台树——系统侧和 Home Manager 侧都是如此。`modules/home/base/`
  已经为此存在，所以 darwin 主机可以 import 共用的桶，而不必把 `home/nixos/` 一起拉进来。

`modules/base/` 在此之前保持为空。今天看起来可以共用的设置，实际住在 `nixos/base/core/nix.nix` 和
`nixos/desktop/fonts.nix`；把一个设置提升到 `base/` 只有在出现第二个使用方之后才有回报，提前提升
只会让配置散开。只有名字在 NixOS 与 nix-darwin 两边都存在的选项才符合条件——`nix.settings`、
`fonts.packages`、`nixpkgs.overlays`、`environment.systemPackages`。
