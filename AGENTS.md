# Agent Instructions

This repository is a Nix flake for NixOS hosts using a "tmpfs as root" layout: the root filesystem is wiped on every boot, and only state registered with the [preservation](https://github.com/nix-community/preservation) module survives, on an encrypted Btrfs volume. Keep the configuration declarative, composable, and easy to validate before deployment.

## Repository layout

```text
flake.nix                 # inputs and outputs
hosts/
├── default.nix           # host discovery: every hosts/<name>/ becomes nixosConfigurations.<name>
└── <name>/               # one directory per host
    ├── default.nix       # feature switches and host metadata
    └── ...               # host-local modules (e.g. hardware.nix)
modules/
├── default.nix           # recursively imports every module; defines user'/hm' aliases
├── README.md             # the layout rules; read it before adding a module
├── base/                 # reserved: settings identical on NixOS and nix-darwin
├── darwin/               # reserved: nix-darwin system modules
├── nixos/
│   ├── base/core/        # identity, users, nix, i18n, sops, firewall, logging (core'.*)
│   ├── base/hardware/    # disko, persistence, boot/, gpu, bluetooth, brightness (hardware'.*)
│   ├── base/services/    # daemons: openssh, networkmanager, pipewire, zram, ... (services'.*)
│   ├── desktop/          # greetd, niri, noctalia, fcitx5, fonts, file-manager (desktop'.*)
│   └── server/           # reserved: headless-only modules
└── home/
    ├── default.nix       # platform entry: imports ./base plus ./nixos
    ├── base/
    │   ├── default.nix   # shared list: persist' options, account settings, bucket imports
    │   ├── core/         # draws nothing of its own (shell, git, CLI packages)
    │   ├── tui/          # takes over the terminal (agents, lazygit, monitors)
    │   └── gui/          # opens a window (terminal, browsers, editors, theme)
    ├── nixos/            # Home Manager settings only NixOS needs (systemd.user, ...)
    └── darwin/           # reserved: Home Manager settings only macOS needs
vars/default.nix          # shared non-secret user values
Justfile                  # task recipes
```

## Host discovery

Every directory under `hosts/` that contains a `default.nix` becomes a host; the directory name is the host name, passed to modules as `hostName`. Adding a host means creating `hosts/<name>/default.nix` — nothing else in the flake changes.

Host files are ordinary NixOS modules:

- `hosts/<name>/default.nix` states what makes the host different: feature switches, timezone, and imports of host-local files.
- Platform-specific settings (disk layout, boot, firmware, services bound to this machine's hardware) belong in host-local modules such as `hardware.nix`; user-facing services stay in `default.nix`.

## Module conventions

- A file under `modules/nixos/`, `modules/darwin/` or `modules/base/` is imported automatically. A file under `modules/home/` must be added to the import list in `modules/home/base/default.nix`; `modules/home/default.nix` stops the walk and is the platform entry.
- System modules expose options under a prime-namespaced attribute (`core'.*`, `hardware'.*`, `services'.*`, `desktop'.*`), with an `enable` option via `lib.mkEnableOption` gated by `lib.mkIf`. The namespace follows the directory: `nixos/base/core` → `core'.*`, `nixos/desktop` → `desktop'.*`.
- `modules/default.nix` defines the aliases `user'.*` (`users.users.<vars.username>`) and `hm'.*` (`home-manager.users.<vars.username>`).
- Home Manager modules report their runtime state through `persist'.directories` and `persist'.files`; the persistence module merges them into `preservation'.user`.
- Prefer a shared module over copying settings into hosts; keep one reusable capability per module.
- Read `modules/README.md` before deciding where a new module goes. In short: `nixos/base` if any NixOS host may use it, `nixos/desktop` if it only makes sense with a screen, `home/base/{core,tui,gui}` by what the program draws, `home/nixos` for Home Manager settings that need systemd or Linux-only packages.

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
- The scope reflects the changed path or component: `{host}` or `{host}/{service}` for host-specific changes, the module area (`core`, `hardware`, `services`, `desktop`, `home`, `modules`) for shared modules, `flake` for flake-level files and host discovery, `docs` for documentation.
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
