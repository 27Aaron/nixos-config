# Security

How this configuration is kept secure: the controls it enforces and how they are checked, the flake inputs it trusts, and the procedures for secrets, updates and incidents. A control written in Nix is not proof that it is active on the running machine; the [runtime checks](#runtime-checks) are. Accepted exceptions live in [WORKAROUNDS.md](WORKAROUNDS.md#security-exceptions).

## Controls and how they are checked

The eval tests in [`tests/`](tests/README.md) run on every `just check` and fail the check when a control regresses. NixOS hosts run `shared.nix` and `nixos.nix`; nix-darwin hosts run `shared.nix` and `darwin.nix`.

| Control | Where | Test |
|---|---|---|
| No Nix trusted users, daemon limited to `@wheel` (`@admin` on macOS), signatures required | `modules/base/core/nix.nix`, `modules/nixos/base/core/nix.nix`, `modules/darwin/core/nix.nix` | `nix-trust`, `daemon-access` |
| Inventory of trusted substituters and keys | `modules/base/core/nix.nix`, `modules/nixos/desktop/input-method/vinput.nix` (only with `desktop'.vinput`) | `nix-caches` |
| sshd: keys only, no root login unless `services'.openssh.rootLogin`, no X11 forwarding | `modules/nixos/base/services/openssh.nix` | `ssh` |
| Inventory of open firewall ports per host | services that open ports | `firewall` |
| No password or hash in the configuration; passwords decrypted before users are created | `modules/nixos/base/core/users.nix` | `password-source` |
| sops decrypts only with the user's SSH key, no key file | `modules/nixos/base/core/sops.nix`, `modules/darwin/core/sops.nix` | `sops-key` |
| systemd-boot editor off (also under lanzaboote), immutable users | `modules/nixos/base/hardware/boot/`, `users.nix` | `boot-and-accounts` |
| Secure Boot with owner-generated keys through lanzaboote; keys persisted as `0700` (river) | `modules/nixos/base/hardware/boot/lanzaboote.nix` | `boot-and-accounts`, `private-state` |
| Kernel sysctl baseline, blocked modules, user namespaces kept, hibernation compatible | `modules/nixos/base/core/kernel-hardening.nix` | `kernel` |
| Editor and agent trust prompts on | `modules/home/nixos/gui/editors/`, `modules/home/*/tui/agents/` | `editor-and-agent-trust` |
| Credential and history directories persisted as `0700` | each module's `persist` entries | `private-state` |
| `execWheelOnly` off while btrbk relies on sudo | `modules/nixos/base/services/btrbk.nix` | `btrbk-sudo` |
| Sandboxed apps are installed only in their nixpak form | `modules/home/nixos/gui/nagram.nix`, `lib/nixpak/` | `sandboxed-apps` |

An app gets a nixpak sandbox when it is third-party, handles untrusted content, and does not need the user's files.

### Runtime checks

Run these after a switch or reboot that touches security settings. On NixOS:

```bash
nix config show trusted-users                      # root
nix config show allowed-users                      # @wheel
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication) '   # no / no
sudo nft list chain inet nixos-fw input-allow      # only the expected ports
systemctl --failed
bootctl status | grep 'Secure Boot'             # enabled (user), on Secure Boot hosts
sudo sbctl verify                                  # all stubs signed, on Secure Boot hosts
```

On macOS:

```bash
nix config show trusted-users                      # root
nix config show allowed-users                      # @admin
```

## Flake inputs

Every input below can change what runs on the machine; those that provide system modules run as root during activation. Review an update as a supply-chain event, following *Flake lock bumps* in `AGENTS.md`.

| Input | Provides | Tracks |
|---|---|---|
| `nixpkgs` | everything | `nixos-unstable` |
| `nix-darwin` | nix-darwin system | default branch |
| `home-manager` | user environment | default branch |
| `disko` | NixOS file systems | default branch |
| `preservation` | NixOS persistence | default branch |
| `lanzaboote` | Secure Boot loader and signing tool | release tag |
| `sops-nix` | secret decryption | default branch |
| `llm-agents` | coding agents; trusted cache | default branch |
| `nagram` | Nagram desktop | default branch |
| `fcitx5-vinput` | fcitx5 add-on; trusted cache | tag ([WA-001](WORKAROUNDS.md#pins)) |
| `nixpak` | app sandbox wrapper | default branch |
| `nur-packages`, `fonts`, `secrets` | owner's own repositories | default branch |

Homebrew packages on macOS are not locked by the flake and are updated separately.

## Secrets

Secrets live in the private nix-secrets repository and are decrypted by sops-nix at activation with each host's `~/.ssh/id_ed25519` (ed25519, no passphrase).

Edit a secret without root:

```fish
set -x SOPS_AGE_KEY (ssh-to-age -private-key -i ~/.ssh/id_ed25519)
sops users/password.yaml
set -e SOPS_AGE_KEY
```

Replace a host's key:

1. Generate the new key under another name and print its recipient with `ssh-to-age < new.pub`.
2. In nix-secrets, replace the host's recipient in `.sops.yaml` and run `sops updatekeys` on every file, using a key that can still decrypt them.
3. Update the `secrets` input here, then move the new key to `~/.ssh/id_ed25519` and switch.

## Secure Boot

Hosts with `hardware'.lanzaboote` boot systemd-boot stubs signed with owner-generated keys in `/var/lib/sbctl`, persisted as `0700`. Set up a host in this order; until the keys are enrolled, every step can be undone by switching back to `hardware'.systemd-boot`.

1. Create the keys, then copy them to the persistent volume. Do this before the first switch: preservation bind-mounts `/persistent/var/lib/sbctl` over `/var/lib/sbctl`, so an empty persistent copy would hide the new keys.

   ```bash
   sudo nix shell nixpkgs#sbctl -c sbctl create-keys
   sudo cp -a /var/lib/sbctl /persistent/var/lib/
   sudo chmod 700 /persistent/var/lib/sbctl
   sudo ls /var/lib/sbctl/keys /persistent/var/lib/sbctl/keys   # PK, KEK and db in both
   ```

2. Enable `hardware'.lanzaboote` in place of `hardware'.systemd-boot`, then `just switch`. `sudo sbctl verify` must report every file as signed except the kernels and initrds under `/boot/EFI/nixos/`. Remove the entries plain systemd-boot left behind, which lanzaboote no longer updates and which would boot unsigned kernels; the glob needs a root shell because `/boot` is readable only by root:

   ```bash
   sudo sh -c 'rm -v /boot/loader/entries/nixos-*.conf'
   sudo bootctl list | grep source   # only /boot/EFI/Linux/nixos-generation-*.efi
   ```
3. Reboot once with Secure Boot still off, and confirm that the host boots and `/var/lib/sbctl/keys` survived.
4. In the firmware, set a firmware password and put Secure Boot into Setup Mode by clearing the platform key (an option such as *Reset To Setup Mode* or *Delete PK*). Do not erase all Secure Boot variables: that also drops the revocation list (dbx).
5. Back in NixOS, `sudo sbctl status` must show `Setup Mode: ✗ Enabled` before you enroll the keys with `sudo sbctl enroll-keys`. Many firmwares leave Setup Mode only at the next boot, so reboot, turn Secure Boot on in the firmware if it is off, and check that `bootctl status` shows `Secure Boot: enabled (user)`.

Add `--microsoft` to `enroll-keys` if the host must boot Microsoft-signed media, or if the firmware loads option ROMs, which are signed with Microsoft's key and would otherwise be refused. The TPM event log records each option ROM as an `EV_EFI_BOOT_SERVICES_DRIVER` event; the second command checks that the log was read at all.

```bash
sudo nix shell nixpkgs#tpm2-tools -c sh -c 'tpm2_eventlog /sys/kernel/security/tpm0/binary_bios_measurements' | grep -c EV_EFI_BOOT_SERVICES_DRIVER
sudo nix shell nixpkgs#tpm2-tools -c sh -c 'tpm2_eventlog /sys/kernel/security/tpm0/binary_bios_measurements' | grep -c EventType
```

The NixOS installer is not signed with these keys; disable Secure Boot in the firmware to boot it for recovery. For a host that fails signature checks after an interrupted install, see [lanzaboote's troubleshooting guide](https://github.com/nix-community/lanzaboote/blob/v1.2.0/docs/explanation/troubleshooting.md).

## Updating

1. Update inputs (`just update` or `just update-input <name>`) and audit the change as described in `AGENTS.md`.
2. `just check` must pass. `just build` prints the package diff against the running system; read it.
3. `just switch`. On NixOS, reboot if the kernel or initrd changed: a different `readlink -f /run/booted-system/kernel` and `readlink -f /nix/var/nix/profiles/system/kernel` means a reboot is pending.
4. If something breaks, roll back: the boot menu or `nixos-rebuild switch --rollback` on NixOS, `darwin-rebuild --rollback` on macOS.

Check for updates at least weekly, and immediately when an actively exploited vulnerability affects a package in use: [NixOS security advisories](https://github.com/NixOS/nixpkgs/security/advisories), [CISA Known Exploited Vulnerabilities](https://www.cisa.gov/known-exploited-vulnerabilities-catalog).

## If compromise is suspected

1. Disconnect the network.
2. From another trusted machine, rotate what the host held: the account password, SSH keys (remove the old public keys from `vars/` and GitHub), tokens, and the secrets in nix-secrets that the host could decrypt.
3. Reinstall from this flake rather than cleaning the running system, and copy back only data you have checked.

Switching to an older generation does not undo a compromise.
