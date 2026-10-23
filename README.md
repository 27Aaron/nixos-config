<h2 align="center">❄️ Aaron's Nix Config ❄️</h2>

<p align="center">
  <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="400" alt="Catppuccin Macchiato color palette" />
</p>

<p align="center">
  <a href="https://nixos.org/">
      <img src="https://img.shields.io/badge/NixOS-26.11-informational.svg?style=for-the-badge&logo=nixos&color=F2CDCD&logoColor=D9E0EE&labelColor=302D41"></a>
  <a href="https://github.com/nix-community/home-manager">
    <img alt="Home Manager" src="https://img.shields.io/badge/Home%20Manager-declarative-7EBAE4?style=for-the-badge&logo=nixos&color=F2CDCD&logoColor=D9E0EE&labelColor=302D41" />
  </a>
</p>

## Overview

A flake for NixOS and nix-darwin hosts.

- **Ephemeral root:** `/` is a tmpfs wiped on every boot; only state registered with [preservation](https://github.com/nix-community/preservation) survives.
- **Storage:** LUKS2 with FIDO2 or TPM2 unlock, Btrfs subvolumes, btrbk snapshots of the persistent volume, and an encrypted swapfile for hibernation.
- **Desktop:** niri with the Noctalia shell, greetd, PipeWire, and Fcitx5 with Rime.
- **Gaming:** Steam with GE-Proton and DW-Proton, GameMode and MangoHud, with its game library on a Btrfs subvolume that snapshots skip.
- **Secrets:** sops-nix, with the encrypted files kept in a separate private repository.
- **Modules:** collected automatically and off by default; a host only flips switches.

## Hosts

| Host | Machine | Role |
|---|---|---|
| `river` | MECHREVO WUJIE 14XA, Ryzen 7 8845HS | laptop, niri desktop |
| `luna` | MacBook Pro 16-inch (2023), Apple M2 Max | laptop, macOS (nix-darwin) |
| `router` | Proxmox VM, 4 vCPU, 1 GB | headless server, LAN gateway with dae |
| `elaina` | Beelink SER6 Pro VEST, Ryzen 7 7735HS | headless home server |

## Layout

| Path | Contents |
|---|---|
| [`hosts/`](hosts/README.md) | one directory per machine; each becomes a `nixosConfigurations` or `darwinConfigurations` entry |
| [`modules/`](modules/README.md) | system and Home Manager modules, grouped by where they run |
| `vars/` | shared non-secret values such as the user name and SSH public keys |
| [`tests/`](tests/README.md) | eval tests for security settings, run by `just check` |
| `lib/` | the module collector |

## Security

[SECURITY.md](SECURITY.md) lists the security controls and how each is checked, the trusted flake inputs, and the secret and update procedures; [WORKAROUNDS.md](WORKAROUNDS.md) lists temporary workarounds and accepted exceptions with their removal conditions.

## References

- [Misterio77/Foundry](https://github.com/Misterio77/Foundry)
- [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)
- [xddxdd/nixos-config](https://github.com/xddxdd/nixos-config)
