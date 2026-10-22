# Agent Instructions

This repository is a Nix flake for NixOS hosts using a "tmpfs as root" layout: the root filesystem is wiped on every boot, and only state registered with the [preservation](https://github.com/nix-community/preservation) module survives, on an encrypted Btrfs volume. Keep the configuration declarative, composable, and easy to validate before deployment.

## Repository layout

```text
flake.nix                 # inputs and outputs
lib/default.nix           # listModules: the recursive module collector
hosts/
├── default.nix           # host discovery: every hosts/nixos/<name>/ becomes nixosConfigurations.<name>
├── nixos/<name>/         # one directory per NixOS host
│   ├── default.nix       # feature switches and host metadata
│   └── ...               # host-local modules (e.g. hardware.nix)
└── darwin/               # reserved: nix-darwin hosts
modules/
├── base/core/            # always-on system modules shared by NixOS and nix-darwin (aliases, fish, nix)
├── darwin/               # reserved: nix-darwin system modules
├── nixos/
│   ├── base/core/        # always on: users, hostname, locale, firewall, logging, nix tools, Home Manager
│   ├── base/hardware/    # disko, persistence, boot/, gpu, bluetooth, yubikey (hardware'.*)
│   ├── base/services/    # daemons usable on any NixOS host, servers included (services'.*)
│   ├── desktop/          # greetd, niri, noctalia, input-method/, power/, pipewire (desktop'.*)
│   └── server/           # server-only modules: fail2ban, initrd-ssh (server'.*)
└── home/
    ├── base/             # Home Manager modules shared by Linux and macOS
    │   ├── core/         # always on: account settings, persist' options
    │   ├── cli/          # draws nothing of its own: shell, git, toolchain (cli'.*)
    │   ├── tui/          # takes over the terminal: agents, lazygit, monitors (tui'.*)
    │   └── gui/          # opens a window: browsers, editors, kitty (gui'.*)
    ├── nixos/            # Linux only: core/ (cache entries), gui/ (GTK/Qt theme, XDG, Linux-only apps)
    └── darwin/           # reserved: Home Manager modules only macOS needs
vars/default.nix          # shared non-secret user values
Justfile                  # task recipes
```

Every major directory has a `README.md` with its placement rules; read it before adding a file there.

## Host discovery

Every directory under `hosts/nixos/` that contains a `default.nix` becomes a host; the directory name is the host name, passed to modules as `hostName`. Adding a host means creating `hosts/nixos/<name>/default.nix` — nothing else in the flake changes. `hosts/darwin/` is reserved; the first Mac also needs a `nix-darwin` input and `darwinConfigurations` in `hosts/default.nix`.

Host files are ordinary NixOS modules:

- `hosts/nixos/<name>/default.nix` states what makes the host different: feature switches, timezone, and imports of host-local files.
- Platform-specific settings (disk layout, boot, firmware, services bound to this machine's hardware) belong in host-local modules such as `hardware.nix`; user-facing services stay in `default.nix`.

## Module conventions

- Modules are collected automatically by `listModules` in `lib/default.nix`: a NixOS host loads `modules/base` and `modules/nixos`, and its Home Manager user loads `modules/home/base` and `modules/home/nixos`. A subdirectory with a `default.nix` is loaded through that file only.
- Place a module at the most general level where it works: `base/` for both system platforms, `nixos/base/` for any NixOS host including servers, `nixos/desktop/` only with a screen, `nixos/server/` only on servers. `modules/README.md` lists the full order.
- Modules under a `core/` directory are always on and have no `enable` option; keep them limited to what every host needs. Every other system module is off by default: it exposes options under a prime-namespaced attribute (`hardware'.*`, `services'.*`, `desktop'.*`, `server'.*`), with an `enable` option via `lib.mkEnableOption` gated by `lib.mkIf`. The namespace follows the directory; grouping subdirectories such as `desktop/input-method/` do not add a level.
- `modules/base/core/aliases.nix` defines the aliases `user'.*` (`users.users.<vars.username>`) and `hm'.*` (`home-manager.users.<vars.username>`).
- Home Manager modules follow the same rule: outside `core/` each one has an `enable` option under `cli'.*`, `tui'.*` or `gui'.*` (by interface, not by platform), and a host turns it on through `hm'`, for example `hm'.gui'.zed.enable = true`. Place a Home Manager module in `home/base/` only if it works on macOS too; anything relying on systemd, XDG or GTK goes to `home/nixos/`.
- Home Manager modules report their runtime state through `persist'.directories` and `persist'.files`; the persistence module merges them into `preservation'.user`.
- Keep one program or one concern per file. When a module outgrows one file, turn it into a directory with a `default.nix` entry.

## Persistence and secrets

- With a tmpfs root, nothing outside the registered paths survives a reboot. Anything a program must keep must appear in `preservation'.os.*`, `preservation'.user.*`, or the `persist'` bridge.
- The machine-id uses the bind-mount recipe plus a suppressed `systemd-machine-id-commit.service`; do not mix in the symlink recipe's commit override.
- `vars/` holds shared non-secret values. Credentials and secrets belong in the separate private repository — do not commit them here.

## Style and formatting

- Two spaces for indentation, no tabs, LF line endings, a final newline, and no trailing whitespace.
- Run the repository formatter with `nix fmt` after editing Nix files.
- Format files changed by the task; do not reformat unrelated files.
- Preserve existing naming conventions when extending a module.

## Validation

```bash
nix fmt
just check    # fmt --check, deadnix, and nix flake check --no-build --all-systems
just build    # build a host; defaults to the local hostname, or pass one explicitly
```

A focused change may be validated by evaluating the affected options, for example `nix eval .#nixosConfigurations.<name>.config.<option>`. Build every affected host when changing host discovery, shared modules, or flake inputs.

## Deployment

Deployment is manual and must be explicitly requested; never run a switch or remote deployment as a side effect of validation.

```bash
just switch [target]                # apply a host's configuration locally
just deploy <target> <user>@<host>  # remote deployment
```

Persistence-related changes only take effect across a reboot; reboot before trusting them.

## Commit messages

Use Conventional Commit titles with a path-based scope:

```text
type(scope): description
```

- Allowed types are `feat`, `fix`, `refactor`, `chore`, and `WIP`. Use `WIP` only for an explicitly temporary work-in-progress snapshot.
- The commit title uses lowercase English text and never ends with a period. Keep the body readable with normal capitalization when it contains proper names or explanatory sentences.
- The scope reflects the changed path or component: `{host}` or `{host}/{service}` for host-specific changes, the module area (`core`, `hardware`, `services`, `desktop`, `server`, `darwin`, `home`, `modules`) for shared modules, `flake` for flake-level files, `lib/` and host discovery, `docs` for documentation.
- Keep the title concise and describe the resulting change, not the list of edited files.

### Flake lock bumps

When updating an input in `flake.lock`, describe the upstream change instead of only mentioning the lock file or revision hashes.

1. Run `nix flake update <input>` and record the old and new revisions from its output or from `git diff -- flake.lock`.
2. Identify the upstream repository and inspect the change range. For a GitHub input, use the compare API or `gh`:

   ```bash
   curl -s https://api.github.com/repos/<owner>/<repo>/compare/<old>...<new>
   # or
   gh api repos/<owner>/<repo>/compare/<old>...<new>
   ```

3. Review the commits or changed files and keep only meaningful changes in the commit body.
4. Use a title naming the input, followed by the short revision range and a brief bullet list:

   ```text
   chore(flake): update home-manager input

   Update home-manager from f6c09b0b to 70386bb7 (2 commits):
   - summarize the meaningful change
   - summarize another relevant file or commit
   ```

For multiple inputs, name all of them in the title or split the updates into separate commits. Do not claim details that are not supported by the upstream changelog or the local diff.
