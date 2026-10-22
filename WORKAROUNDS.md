# Workarounds

Temporary workarounds, version pins and accepted security exceptions, each with the condition under which it can go away. Without this list, a fix that lands upstream leaves the local workaround behind, and nobody remembers why it is there.

## How to use

- **Adding:** a change that introduces a workaround, pin or exception adds a row here in the same commit, with a concrete removal condition, and mentions the ID in a comment next to the code.
- **Removing:** once the condition is met, delete the code and the row, and mention the ID in the commit message.
- **Reviewing:** after a nixpkgs, kernel or BIOS update, check the rows whose condition depends on it.

`git grep WA-` finds every row together with the code it refers to.

## Pins

| ID | What and where | Why | Remove when | Added |
|---|---|---|---|---|
| WA-001 | `fcitx5-vinput` pinned to tag `v2.4.2` and not following `nixpkgs` — `flake.nix`, used by `modules/nixos/desktop/input-method/vinput.nix` | The `fcitx5-vinput.cachix.org` binaries are built against upstream's own lock; following `nixpkgs` would compile sherpa-onnx locally. The cost is a second nixpkgs that only gets security fixes when upstream updates its lock, and a trusted binary cache. | The package reaches nixpkgs, or a local build becomes acceptable; then follow `nixpkgs` and drop the cache from `modules/base/core/nix.nix` and `tests/security.nix`. Bump the tag deliberately until then. | 2026-10-18 (#152) |

## Workarounds

| ID | What and where | Why | Remove when | Added |
|---|---|---|---|---|
| WA-002 | Re-bind `acpi-button` with `lid_init_state=open` after hibernation — `hosts/nixos/river/power.nix` | `HibernateMode=shutdown` cuts power, so opening the lid sends no event, while `_LID` is restored as closed from the image; logind then suspends again in a loop. | With the hook removed, resuming from hibernation no longer suspends again. Check after a BIOS or kernel update. | 2026-10-22 (#177) |
| WA-003 | Re-bind the I2C touchpad (`UNIW0001`, `i2c_hid_acpi`) after resume — `hosts/nixos/river/power.nix` | The touchpad does not re-enumerate after hibernation. | The touchpad works after resume without the re-bind. Check after a BIOS or kernel update. | 2026-10-22 (#176) |
| WA-004 | `boot.consoleLogLevel = 3` — `hosts/nixos/river/hardware.nix` | The firmware's ACPI errors flood the boot screen; they stay in the journal. | A BIOS update fixes the ACPI tables. | 2026-10-18 (#148) |
| WA-005 | `programs.ssh.systemd-ssh-proxy.enable = false` — `modules/nixos/base/core/ssh-client.nix` | The included systemd drop-in is owned by `nobody` in the store; OpenSSH 10 then rejects the whole `ssh_config`, so every `ssh` and `git` call fails. | nixpkgs or OpenSSH stop failing on the include. | 2026-10-20 (#164) |
| WA-006 | `~/.ssh/config` copied at activation instead of linked by `home.file` — `modules/home/base/cli/ssh.nix` | OpenSSH 10 requires the user to own `~/.ssh/config`; a Home Manager link points to a root-owned store file. | Home Manager or OpenSSH accept a store link. | 2026-10-19 (#157) |
| WA-007 | Nagram wrapper sets `XKB_CONFIG_ROOT` and rewrites its D-Bus service — `modules/home/nixos/gui/nagram.nix` | The upstream binary bundles a libxkbcommon that only searches `/usr/share/X11/xkb` and segfaults in a Wayland callback; D-Bus activation would bypass the wrapper. | Upstream stops bundling libxkbcommon, or nixpkgs packages Nagram. | 2026-10-16 (#124) |
| WA-008 | keyd maps `rightcontrol` to itself — `hosts/nixos/river/keyboard.nix` | keyd folds right Ctrl into left Ctrl by default. | keyd keeps right-hand modifiers distinct. | 2026-10-19 (#160) |
| WA-009 | dae config assembled into `/etc/dae` by a forced `ExecStartPre` — `modules/nixos/base/services/dae.nix` | The upstream module copies only the entry file and loses the included `config.d`; dae also refuses included files that others can read, which rules out the store. | The nixpkgs dae module supports a configuration directory with includes. | 2026-10-17 (#131) |
| WA-010 | Empty `tmpfiles.d/lastlog2-tmpfiles.conf` — `modules/nixos/base/hardware/persistence.nix` | Its rules conflict with the persisted `/var/lib/lastlog`. | NixOS or preservation stop conflicting; check that removing the override boots without tmpfiles errors. | 2026-10-16 (#125) |
| WA-011 | Empty `plugdev` group — `modules/nixos/base/hardware/yubikey.nix` | libfido2's udev rules name `GROUP="plugdev"`, which NixOS lacks; every boot logs hundreds of parse errors. Access is granted by `TAG+="uaccess"` anyway. | The libfido2 rules in nixpkgs drop `plugdev`. | 2026-10-20 (#163) |
| WA-012 | `VINPUT_ASR_LIBOPUS_PATH` for `vinput-daemon` — `modules/nixos/desktop/input-method/vinput.nix` | The command-line recognizer ignores `LD_LIBRARY_PATH` and exits when it cannot find libopus. | Upstream finds libopus without the variable. | 2026-10-18 (#152) |

## Security exceptions

Deliberate deviations from the rules in `AGENTS.md` and `SECURITY.md`, and gaps that need work outside this repository.

| ID | What and where | Why | Remove when | Added |
|---|---|---|---|---|
| WA-013 | `kernel.kptr_restrict` stays at 1 instead of 2 — `modules/nixos/base/core/kernel-hardening.nix` | dae's eBPF library reads `/proc/kallsyms`, which shows zeros even to root at 2. Level 1 already hides addresses from unprivileged users. | `sudo sysctl kernel.kptr_restrict=2 && sudo systemctl restart dae` keeps dae working; then raise it and update the test. | 2026-10-22 (#191) |
| WA-014 | dae's tproxy port 12345 open on every interface (`openFirewall`) — `modules/nixos/base/services/dae.nix`, `tests/security.nix` | Copied from the upstream recommendation; whether a `wan_interface`-only setup needs it is unverified. | dae keeps proxying with `openFirewall` disabled; then close the port and update `openPorts`. | 2026-10-17 (#129) |
| WA-015 | Unencrypted files in nix-secrets (`hosts/*/*.nix`, including a `.bak`, and `openssh/config`) are copied into the store on river | The `.sops.yaml` rule only encrypts YAML, JSON, dotenv and INI files, and a flake input is copied whole into the world-readable `/nix/store`. | Sensitive values in those files are encrypted, or the files move out of the repository river evaluates. | 2026-10-22 |
| WA-016 | One shared `Servers` age key plus the MacBook key, and no offline recovery key — nix-secrets `.sops.yaml` | Historical setup. A compromised host with the shared key can decrypt every secret, including other servers'. | Each host decrypts with its own key, and every secret is also encrypted to an offline recovery key. | 2026-10-22 |
| WA-017 | Automatic login on river — `desktop'.greetd.autoLogin` in `hosts/nixos/river/default.nix` | The disk only unlocks with the FIDO2 key plus PIN, or the LUKS passphrase, so a second password at login adds little. | Accepted risk; revisit if disk unlock stops requiring a secret. | 2026-07-22 |
