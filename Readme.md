# NixOS configuration

This repository is the source of truth for Muhammad's NixOS systems.

## Hosts

- `vm-aarch64` — NixOS ARM64 VM in VMware Fusion on macOS.
- `wsl` — NixOS-WSL on x86_64 Windows.

Host-specific settings live in `machines/`, reusable system modules in `modules/`, and user/Home Manager configuration in `users/`.

## Apply

From the repository root:

```sh
sudo nixos-rebuild switch --flake .#vm-aarch64
```

On WSL:

```sh
sudo nixos-rebuild switch --flake .#wsl
```

`/etc/nixos` is only bootstrap configuration; day-to-day changes belong in this repository.

## Maintenance

Format Nix files with:

```sh
nix fmt
```

Evaluate the flake before applying changes:

```sh
nix flake check --all-systems --no-build
```

Update pinned inputs deliberately and review `flake.lock`:

```sh
nix flake update
```

`system.stateVersion` and `home.stateVersion` are compatibility settings. Do not bump them during normal NixOS/Home Manager upgrades unless the relevant release notes explicitly require it.
