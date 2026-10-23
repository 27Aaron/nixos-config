# Agent Instructions

This repository is a Nix flake for NixOS hosts using a "tmpfs as root" layout: the root filesystem is wiped on every boot, and only state registered with the [preservation](https://github.com/nix-community/preservation) module survives, on a LUKS-encrypted Btrfs volume. Keep the configuration declarative, composable, and easy to validate before deployment.

## Repository layout

```text
flake.nix          # inputs and outputs
lib/               # module collector and shared nixpak sandbox modules
hosts/             # one directory per host, discovered automatically
modules/
├── base/          # system modules shared by NixOS and nix-darwin
├── nixos/         # NixOS system modules: base/, desktop/, server/
├── darwin/        # nix-darwin system modules
└── home/          # Home Manager modules: base/ always on; shared/, nixos/, darwin/ switchable
tests/             # eval tests run by `just check`
vars/              # shared non-secret values
SECURITY.md        # threat model, trust boundaries, app sandboxes, runtime checks
WORKAROUNDS.md     # temporary workarounds, pins and security exceptions
```

Every major directory has a `README.md` saying what belongs there. Read it before adding a file, and update it when a change makes it stale.

## Host discovery

Every `hosts/nixos/<name>/default.nix` becomes `nixosConfigurations.<name>`, and every `hosts/darwin/<name>/default.nix` becomes `darwinConfigurations.<name>`; the directory name is passed to modules as `hostName`. `default.nix` holds the host's feature switches, timezone and `stateVersion`; settings bound to this machine's hardware go into host-local files split by topic. Anything a second machine could reuse becomes a module under `modules/`.

## Module conventions

- Modules are collected automatically by `listModules` in `lib/default.nix`; a subdirectory with a `default.nix` is loaded through that file only.
- Place a module at the most general level where it works; `modules/README.md` lists the order. Home Manager modules go to `home/base/` only if every host needs them and they work on macOS too; switchable ones go to `home/shared/` when they work on both platforms, otherwise to `home/nixos/` or `home/darwin/`.
- Modules under `core/` and in `home/base/` are always on and have no `enable` option. Every other module is off by default and follows neighboring modules for its option namespace and `enable` switch.
- Keep one program or one concern per file. When a module outgrows one file, turn it into a directory with a `default.nix` entry.

## Persistence

- With a tmpfs root, nothing outside the registered paths survives a reboot. System modules register state in `preservation'.os` or `preservation'.user`; Home Manager modules use `persist`, which the persistence module merges into `preservation'.user`.
- Register state in the module that creates it. `~/.cache` is never persisted as a whole; list only the caches worth keeping.
- Give directories that hold credentials, sessions, keys or history `mode = "0700"`. Preservation's default is `0755`, and it is re-applied on every boot.
- When an upstream module may also enable a service, gate its persisted state on the service's final state (such as `config.hardware.bluetooth.enable`), not on this module's switch.
- Programs that update a file by writing a temporary file and calling `rename()` (logrotate, zsh) fail with `EBUSY` on a single-file bind mount; persist the parent directory instead.
- The machine-id uses the bind-mount recipe plus a suppressed `systemd-machine-id-commit.service`; do not mix in the symlink recipe's commit override.

## Security

- `SECURITY.md` holds the threat model, trust boundaries, the app sandbox decisions, the flake input inventory and runtime checks. Update it in the same change when a change moves a security boundary, adds an input, or sandboxes an app.
- Credentials and secrets belong in the private `nix-secrets` repository and reach the system through sops-nix. `inputs.secrets` is copied into the world-readable `/nix/store`, so read only encrypted files, or files with nothing sensitive in them (like the SSH host aliases), from it at evaluation time. `vars/` holds non-secret values only. Account passwords come from `users/password.yaml` in nix-secrets, decrypted with `neededForUsers` before users are created; never put a password or hash in the configuration. sops is a core module because every host needs it for that. Hosts decrypt with the user's `~/.ssh/id_ed25519` (`sops.age.sshKeyPaths`; river reads it from `/persistent`), never with a key file. See *Secrets* in `SECURITY.md` before changing keys.
- Do not add users to `nix.settings.trusted-users`: a trusted user can disable signature checks and import arbitrary store paths, which amounts to passwordless root. Only `@wheel` may connect to the daemon (`allowed-users`); on macOS, where `wheel` holds only root, it is `@admin`.
- Root SSH login is opt-in per host through `services'.openssh.rootLogin`, for remote deployment targets only. Other hosts accept the user's key and escalate with `sudo`. Root keeps its authorized keys because initrd SSH unlock uses them.
- `security.sudo.execWheelOnly` stays off: the upstream btrbk module runs as its own user and calls `btrfs` through sudo rules.
- The kernel baseline in `core/kernel-hardening.nix` uses `lib.mkDefault`, so a host overrides a value with a plain definition, never `mkForce`. Keep user namespaces on (the Nix build sandbox needs them), leave `security.protectKernelImage` off (it disables hibernation), and keep `kernel.kptr_restrict` at 1 (dae's eBPF library reads `/proc/kallsyms`). A host that needs a module from `core'.kernel.blockedModules`, such as an IPsec VPN, removes it there.
- Sandboxed desktop apps use the nixpak modules in `lib/nixpak/` and are listed in `sandboxedApps` in `tests/security/shared.nix`. Bind only the paths an app needs: never the whole `$XDG_RUNTIME_DIR` (it holds the niri control socket, which can spawn programs, and the SSH and GPG agents) and never the unfiltered session bus (systemd's user manager can run commands outside the sandbox). An FHS-packaged app can run inside nixpak; the outer sandbox limits what the inner FHS environment sees.
- Keep trust prompts on. Do not set Zed's `session.trust_all_worktrees`, disable VS Code's workspace trust, or alias coding agents to permission-bypass modes; a cloned repository must not be able to run code just by being opened.
- Inputs that do not follow `nixpkgs` (currently `fcitx5-vinput`, for its binary cache) carry their own nixpkgs and only pick up security fixes when upstream updates its lock.

## Workarounds

Record every temporary workaround, version pin and accepted security exception in `WORKAROUNDS.md` in the same change that introduces it: give it the next `WA-NNN` ID and a concrete removal condition, and mention the ID in a comment next to the code. When the condition is met, delete the code and the row and name the ID in the commit message. After a nixpkgs, kernel or BIOS update, recheck the rows that depend on it.

## Style and formatting

- Two spaces for indentation, no tabs, LF line endings, a final newline, and no trailing whitespace.
- Run the repository formatter with `nix fmt` after editing Nix files.
- Format files changed by the task; do not reformat unrelated files.
- Top-level documents (`README.md`, `AGENTS.md`, `SECURITY.md`, `WORKAROUNDS.md`), option descriptions and commit messages are in English. Directory READMEs and Nix comments are in Traditional Chinese with Taiwanese usage (設定, 檔案, 預設, 支援). Markdown prose uses full-width punctuation; Nix comments use half-width `,;:()` with full-width `。、`.
- Comments explain why: a constraint, an upstream quirk, or a rejected alternative. Do not restate what the next line does, and do not add file header comments.

## Validation

```bash
nix fmt
just check    # fmt --check, deadnix, and nix flake check --no-build --all-systems (includes the eval tests)
just build    # build a host; defaults to the local hostname, or pass one explicitly
```

A focused change may be validated by evaluating the affected options, for example `nix eval .#nixosConfigurations.<name>.config.<option>`. Build every affected host when changing host discovery, shared modules, or flake inputs.

The eval tests in `tests/` assert the security rules above on every host and keep inventories of open ports, trusted binary caches and private persisted paths. When a change deliberately alters one of these (a service opens a port, a cache is added, a host is added), update the expectation in `tests/security/` (`shared.nix`, `nixos.nix` or `darwin.nix`) in the same change and say why. Never weaken a test only to make it pass; see `tests/README.md`.

For a refactor or comment-only change that should not alter the system, record the toplevel derivation before and after and compare them:

```bash
nix eval --raw .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath
nix run nixpkgs#nix-diff -- <old.drv> <new.drv>
```

## Deployment

Deployment is manual and must be explicitly requested; never run a switch or remote deployment as a side effect of validation.

```bash
just switch [target]                # apply a host's configuration locally
just deploy <target> root@<host>    # remote deployment; the target needs services'.openssh.rootLogin
```

Persistence-related changes only take effect across a reboot; reboot before trusting them.

## Commit messages

Use Conventional Commit titles with a path-based scope:

```text
type(scope): description
```

- Allowed types are `feat`, `fix`, `refactor`, `chore`, and `WIP`. Use `WIP` only for an explicitly temporary work-in-progress snapshot.
- The commit title uses lowercase English text and never ends with a period. Keep the body readable with normal capitalization when it contains proper names or explanatory sentences.
- Keep the title within 50 characters, `type(scope): ` included. GitHub truncates titles past 72 characters, and a squash merge appends ` (#123)`, so 50 leaves room. Name one resulting change; drop articles and filler words, and move lists and details into the body.
- Wrap the body at 72 characters.
- A pull request title becomes the squash-merge commit title, so it follows the same rules.
- The scope reflects the changed path or component: `{host}` or `{host}/{service}` for host-specific changes, the module area (`core`, `hardware`, `services`, `desktop`, `server`, `darwin`, `home`, `modules`) for shared modules, `flake` for flake-level files, `lib/` and host discovery, `docs` for documentation.
- Describe the resulting change, not the list of edited files.

```text
refactor(home): bind flake packages by name instead of their package set   # 72, too long
refactor(home): bind flake packages directly                               # 44
```

### Flake lock bumps

When updating an input in `flake.lock`, describe the upstream change instead of only mentioning the lock file or revision hashes.

1. Run `nix flake update <input>` and record the old and new revisions from its output or from `git diff -- flake.lock`.
2. Identify the upstream repository and inspect the change range. For a GitHub input, use the compare API or `gh`:

   ```bash
   curl -s https://api.github.com/repos/<owner>/<repo>/compare/<old>...<new>
   # or
   gh api repos/<owner>/<repo>/compare/<old>...<new>
   ```

3. Treat the update as a supply-chain event. For each input that moved, check what this repository consumes from it (see the input table in `SECURITY.md`):
   - For inputs that provide NixOS or Home Manager modules (`home-manager`, `disko`, `preservation`, `sops-nix`), read the changes to the module files that are imported and look for `nix.settings` substituters, trusted keys or trusted users; activation scripts, root services, sudo or polkit rules; `environment.etc` or `home.file` entries that widen ownership or mode; `lib.mkForce` overrides; and import-from-derivation.
   - For package inputs, confirm that the packages used here changed only as described.
   - `just check` catches new caches and open ports; `just build` prints the package diff against the running system.
4. Keep only meaningful changes in the commit body, and call out security fixes explicitly.
5. Use a title naming the input, followed by the short revision range and a brief bullet list:

   ```text
   chore(flake): update home-manager input

   Update home-manager from f6c09b0b to 70386bb7 (2 commits):
   - summarize the meaningful change
   - summarize another relevant file or commit
   ```

Pin a new third-party input to a release tag or a commit when the project publishes releases, rather than tracking a branch; record a pin that exists for a temporary reason in `WORKAROUNDS.md`.

For multiple inputs, use `chore(flake): update flake inputs` and list each input in the body, or split the updates into separate commits. Do not claim details that are not supported by the upstream changelog or the local diff.
