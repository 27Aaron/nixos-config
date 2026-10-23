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
| systemd-boot editor off, immutable users | `modules/nixos/base/hardware/boot/`, `users.nix` | `boot-and-accounts` |
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
