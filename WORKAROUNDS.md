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
| WA-001 | `fcitx5-vinput` pinned to tag `v2.4.2` and not following `nixpkgs` — `flake.nix`, used by `modules/nixos/desktop/input-method/vinput.nix` | The `fcitx5-vinput.cachix.org` binaries are built against upstream's own lock; following `nixpkgs` would compile sherpa-onnx locally. The cost is a second nixpkgs that only gets security fixes when upstream updates its lock, and a trusted binary cache. | The package reaches nixpkgs, or a local build becomes acceptable; then follow `nixpkgs` and drop the cache from `modules/nixos/desktop/input-method/vinput.nix` and `tests/security/shared.nix`. Bump the tag deliberately until then. | 2026-10-18 (#152) |

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
| WA-013 | `kernel.kptr_restrict` stays at 1 instead of 2 — `modules/nixos/base/core/kernel-hardening.nix` | dae's eBPF library reads `/proc/kallsyms`, which shows zeros even to root at 2. | `sudo sysctl kernel.kptr_restrict=2 && sudo systemctl restart dae` keeps dae working; then raise it and update the test. | 2026-10-22 (#191) |
| WA-016 | sops decrypts with the user's own SSH key rather than a root-only key, and the secrets share one set of recipients — `modules/nixos/base/core/sops.nix`, `modules/darwin/core/sops.nix`, nix-secrets `.sops.yaml` | Chosen for simplicity. | Revisit when cleaning up nix-secrets. | 2026-10-22 |
| WA-017 | Automatic login on river — `desktop'.greetd.autoLogin` in `hosts/nixos/river/default.nix` | Disk unlock already requires a secret. | Revisit if disk unlock stops requiring a secret. | 2026-07-22 |
| WA-021 | The owner is in the `gamemode` group — `modules/nixos/desktop/game/gamemode.nix` | GameMode's tuning helpers need it. | GameMode is no longer used, or it no longer needs a group-wide grant. | 2026-10-22 |
| WA-022 | elaina's FIDO2 key is enrolled without a PIN; touch alone unlocks the disk — `hosts/nixos/elaina/storage.nix`, enrollment command in `modules/nixos/base/hardware/disko.nix` | The host has no keyboard. | Revisit if the host gets a keyboard or another unlock method. | 2026-10-23 |
