# Security

This repository configures one personal laptop, `river`. This document records what the configuration protects against, where the trust boundaries are, how each control is checked, and what is still missing. A control written in Nix is not proof that it is active on the running machine; the [runtime checks](#runtime-checks) below are.

## Reporting problems

Open an issue for configuration mistakes, with secrets and exploit details left out. For anything sensitive, contact the owner privately through their GitHub profile first.

## Threat model

River is a single-user laptop that travels and joins untrusted networks. In order of likelihood:

1. **Code running as the user:** a malicious package (npm, PyPI, editor extension), a cloned repository that runs code when opened, or a prompt injection that steers a coding agent. It can read everything the user can, and tries to become root.
2. **Supply chain:** a flake input, an imported NixOS module or a binary cache that ships malicious code, which then runs as root during activation.
3. **A compromised network service** (sshd, dae) trying to go further.
4. **Physical access:** theft, or tampering with the unencrypted boot partition while the laptop is unattended.
5. **Data loss:** a dead or lost disk, or a mistake.

Priorities, in order: patch quickly, expose little, grant least privilege, and be able to recover. Kernel hardening and module blocking are defence in depth, not a substitute for updates.

## Trust boundaries

| Boundary | Current design | Limitation |
|---|---|---|
| Administration | `sudo` needs the account password, which comes from nix-secrets through sops. Nobody is a Nix trusted user; only `@wheel` reaches the daemon. | Code running as the user can wait for the password to be typed. |
| Network | nftables firewall; only 233/tcp (sshd, keys only, no root login) and 12345/tcp+udp (dae) are open. | The dae port may be unnecessary ([WA-014](WORKAROUNDS.md#security-exceptions)). |
| Disk | LUKS2 unlocked by a FIDO2 key with PIN and touch, or the passphrase; `/` is a tmpfs; persistent state lives on Btrfs inside LUKS. | No Secure Boot: the kernel and initrd on the ESP are unsigned and can be replaced to capture the PIN. |
| Secrets | sops-nix decrypts secrets from the private nix-secrets repository at activation. | One shared host key and no offline recovery key ([WA-016](WORKAROUNDS.md#security-exceptions)); unencrypted files in that repository land in the world-readable store ([WA-015](WORKAROUNDS.md#security-exceptions)). |
| Supply chain | Locked inputs; an inventory of trusted caches and keys enforced by the eval tests. See [inputs](#flake-inputs). | A lock file is not an audit; most inputs track a branch. |
| Desktop apps | Nagram runs in a nixpak sandbox: it sees only its data directory and `~/Downloads/Telegram`, reaches other files through the file chooser portal, and talks to a filtered D-Bus. Trust prompts stay on in Zed, VS Code and Claude Code. | The other apps, including closed-source ones, can still read `~/.ssh`, browser profiles and tokens. |
| Recovery | Eight boot generations; btrbk snapshots `@persistent` twice a day. | Snapshots live on the same disk; there is no off-device backup. |

## Flake inputs

Every input below can change what runs on the machine. Those that provide NixOS modules run as root during activation.

| Input | Provides | Runs as | Tracks |
|---|---|---|---|
| `nixpkgs` | everything | root and user | `nixos-unstable` |
| `home-manager` | NixOS module, user environment | root (activation service) and user | default branch |
| `disko` | NixOS module (file systems) | root | default branch |
| `preservation` | NixOS module (bind mounts in the initrd) | root | default branch |
| `sops-nix` | NixOS module, secret decryption | root | default branch |
| `llm-agents` | claude-code, dsh, claude-desktop; trusted cache `cache.numtide.com` | user | default branch |
| `nagram` | Nagram desktop, from an upstream binary | user | default branch |
| `fcitx5-vinput` | fcitx5 add-on and daemon, which see every keystroke; trusted cache | user | tag `v2.4.2` ([WA-001](WORKAROUNDS.md#pins)) |
| `nixpak` | sandbox wrapper for desktop apps (bubblewrap, xdg-dbus-proxy) | user | default branch (no releases) |
| `nur-packages`, `fonts`, `secrets` | owner's own repositories | user, data | default branch |

Review an update to these as a supply-chain event; the procedure is in `AGENTS.md` under *Flake lock bumps*.

## Controls and how they are checked

The eval tests in [`tests/`](tests/README.md) run on every `just check` and fail the check when a control regresses:

| Control | Where | Test |
|---|---|---|
| No Nix trusted users, daemon limited to `@wheel`, signatures required | `modules/base/core/nix.nix`, `modules/nixos/base/core/nix.nix` | `nix-trust` |
| Inventory of trusted substituters and keys | `modules/base/core/nix.nix` | `nix-caches` |
| sshd: keys only, no root login unless `services'.openssh.rootLogin`, no X11 forwarding | `modules/nixos/base/services/openssh.nix` | `ssh` |
| Inventory of open firewall ports per host | services that open ports | `firewall` |
| No password or hash in the configuration; passwords decrypted before users are created | `modules/nixos/base/core/users.nix` | `password-source` |
| systemd-boot editor off, immutable users | `modules/nixos/base/hardware/boot/`, `users.nix` | `boot-and-accounts` |
| Kernel sysctl baseline, blocked modules, user namespaces kept, hibernation compatible | `modules/nixos/base/core/kernel-hardening.nix` | `kernel` |
| Editor and agent trust prompts on | `modules/home/base/gui/editors/`, `tui/agents/` | `editor-and-agent-trust` |
| Credential and history directories persisted as `0700` | each module's `persist'` entries | `private-state` |
| `execWheelOnly` off while btrbk relies on sudo | `modules/nixos/base/services/btrbk.nix` | `btrbk-sudo` |
| Sandboxed apps are installed only in their nixpak form | `modules/home/nixos/gui/nagram.nix`, `lib/nixpak/` | `sandboxed-apps` |

### Runtime checks

Run these after a switch or reboot that touches security settings:

```bash
nix config show trusted-users                      # root
nix config show allowed-users                      # @wheel
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication) '   # no / no
sudo nft list chain inet nixos-fw input-allow      # only the expected ports
sysctl fs.protected_fifos fs.protected_regular dev.tty.ldisc_autoload   # 2 2 0
sudo modprobe sctp                                 # must fail
systemctl --failed
```

## Updating

1. Update inputs (`just update` or `just update-input <name>`) and audit the change as described in `AGENTS.md`.
2. `just check` must pass. `just build` prints the package diff against the running system; read it.
3. `just switch`, then reboot if the kernel or initrd changed. A new kernel is only active after a reboot:

   ```bash
   readlink -f /run/booted-system/kernel             # running
   readlink -f /nix/var/nix/profiles/system/kernel   # selected for the next boot
   ```

   Different paths mean a reboot is pending.
4. If something breaks, pick the previous generation in the boot menu or run `nixos-rebuild switch --rollback`.

Check for updates at least weekly, and immediately when an actively exploited vulnerability affects a package in use. Useful feeds: [NixOS security advisories](https://github.com/NixOS/nixpkgs/security/advisories), the [NixOS Discourse security category](https://discourse.nixos.org/c/announcements/security/56) and the [CISA Known Exploited Vulnerabilities catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog).

## If compromise is suspected

1. Disconnect the network.
2. From another trusted machine, rotate what the laptop held: the account password in nix-secrets, SSH keys (and remove the old public keys from `vars/` and GitHub), GitHub and agent tokens, and the age key if root was compromised.
3. Reinstall from this flake rather than cleaning the running system, then restore data from a backup taken before the compromise.

Switching to an older generation does not undo a compromise: it only changes the system configuration, not stolen secrets or modified data.

## Remaining work

| Priority | Work | Notes |
|---|---|---|
| P1 | Off-device, encrypted backups | Deferred. Snapshots on the same disk do not survive loss or theft; plan: restic to object storage with deletion protection. |
| P1 | Fix the nix-secrets exposure and key layout | [WA-015](WORKAROUNDS.md#security-exceptions), [WA-016](WORKAROUNDS.md#security-exceptions); work in the nix-secrets repository. |
| P2 | Secure Boot with lanzaboote | Deferred. Only worth it together with a firmware setup password, otherwise anyone at the keyboard can switch it off. |
| P2 | Sandbox the remaining third-party GUI apps | Nagram is done; next candidates are dsh-desktop and magpie. Test input method and file chooser for each. |
| P2 | Document how to reinstall river from scratch | disko, FIDO2 enrollment, the age key, `resume_offset`. |
| P3 | Verify whether dae needs its open port | [WA-014](WORKAROUNDS.md#security-exceptions) |

Decided against: CI. `just check` runs locally before every pull request, and CI would need access to the private secrets input.

Record temporary exceptions in [WORKAROUNDS.md](WORKAROUNDS.md) with a removal condition.
