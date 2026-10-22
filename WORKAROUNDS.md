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
| WA-007 | `xkeyboard-config` added to Nagram's FHS environment — `modules/home/nixos/gui/nagram.nix` | The upstream binary bundles a libxkbcommon that only searches `/usr/share/X11/xkb` and segfaults in a Wayland callback without it. | Upstream stops bundling libxkbcommon, or nixpkgs packages Nagram. | 2026-10-16 (#124) |
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
| WA-016 | river decrypts with the user's own SSH key, `~/.ssh/id_ed25519`, which has no passphrase, and every secret in nix-secrets is encrypted to the same recipients (MacBook, the shared `Servers` key, river) — `modules/nixos/base/core/sops.nix`, nix-secrets `.sops.yaml` | Chosen for simplicity. Any process running as the user can read the key and decrypt every secret without root (sandboxed apps cannot see `~/.ssh`); a server holding the `Servers` key can decrypt river's secrets, and river can decrypt the servers'. | Accepted for now; revisit when cleaning up nix-secrets: give river's files their own rule without `Servers`, or move the key to a root-only path. | 2026-10-22 |
| WA-018 | Jovian-NixOS system changes that `jovian.steam.enable` applies without an opt-out — `modules/nixos/desktop/steam.nix` | `TAG+="uaccess"` on every USB device and every `hidraw` node, so any process of the logged-in user can read raw HID reports (including keyboards, bypassing Wayland's input isolation); a polkit rule letting active local `users` modify NetworkManager system connections (the owner is already in `networkmanager`); `cap_sys_nice` on gamescope and a hard `nice` limit of -8 for everyone; root services steamos-manager and inputplumber; logind ignores the power key, which only powerbuttond handles inside gaming mode. Needed for Steam Input, controller support and the Steam Deck UI. | Jovian makes these optional, or Steam is removed. | 2026-10-22 |
| WA-017 | Automatic login on river — `desktop'.greetd.autoLogin` in `hosts/nixos/river/default.nix` | The disk only unlocks with the FIDO2 key plus PIN, or the LUKS passphrase, so a second password at login adds little. | Accepted risk; revisit if disk unlock stops requiring a secret. | 2026-07-22 |
