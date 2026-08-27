# My NixOS Configuration

This repository is the source of truth for my NixOS development environments.
It is intentionally small, explicit, and shaped around the systems I actually
use: an ARM64 NixOS virtual machine on macOS and an x86_64 NixOS-WSL system.

The workflow was inspired by
[Mitchell Hashimoto's NixOS configuration](https://github.com/mitchellh/nixos-config)
and his [development environment video](https://www.youtube.com/watch?v=ubDMLoWz76U).
This is not a copy of his setup: every input, module, and package here exists for
my own environment.

This repository is not intended to be a turnkey NixOS distribution. Read the
configuration before using it: it contains machine-specific disk, network,
display, user, and security assumptions.

## How I work

macOS remains the host operating system, while the NixOS VM is the main Linux
development environment for editing, compiling, containers, and local services.
This keeps the host integration on macOS and the development stack in a
declarative Linux system.

The VM runs in VMware Fusion on Apple Silicon. NixOS provides i3, Kitty, Neovim,
Fish, Git, Go, compiler tooling, and Docker. Folders exposed by VMware Fusion
are available inside the guest under `/host`.

WSL is a second, console-focused target for Windows. It shares the user shell,
editor, and command-line tooling with the VM, while graphical VM-only programs
remain disabled.

The macOS host itself is not managed by this flake. There is deliberately no
`nix-darwin` configuration yet.

## Systems

| Flake output | Platform | Purpose |
| --- | --- | --- |
| `vm-aarch64` | `aarch64-linux` | Main NixOS VM in VMware Fusion on macOS |
| `wsl` | `x86_64-linux` | NixOS-WSL environment on Windows |

Both systems use NixOS 26.05, Home Manager 26.05, and a committed `flake.lock`.
Home Manager is integrated into each NixOS system rather than activated as a
standalone configuration.

## Repository layout

```text
.
├── flake.nix                         # Inputs and system composition
├── flake.lock                        # Pinned dependency revisions
├── Makefile                          # VM bootstrap, secrets, and WSL helpers
├── machines/
│   ├── hardware/vm-aarch64.nix       # VM disk and filesystem layout
│   ├── vm-aarch64.nix                # VMware/i3/Retina host configuration
│   └── wsl.nix                       # NixOS-WSL host configuration
├── modules/
│   ├── nixos/common.nix              # Shared NixOS CLI tools and settings
│   └── virtualisation/docker.nix     # Docker and development firewall ports
├── users/muhammad/
│   ├── nixos.nix                     # Linux user, SSH access, and sudo policy
│   ├── home-manager.nix              # Shell, terminal, i3, fonts, and dotfiles
│   └── nvim/                         # Kickstart-based Neovim configuration
└── .github/workflows/
    ├── check.yml                     # Evaluate the flake on pushes and PRs
    └── build-wsl.yml                 # Build and upload the WSL image artifact
```

The layers have distinct responsibilities:

- `machines/` contains facts and settings that belong to a particular host.
- `modules/` contains reusable NixOS behavior shared by one or more hosts.
- `users/muhammad/nixos.nix` defines the operating-system user.
- `users/muhammad/home-manager.nix` defines the user's home environment.
- `flake.nix` explicitly connects those layers; it does not discover files
  automatically.

## Current stack

- Nix flakes and NixOS modules for reproducible system configuration.
- Home Manager for the user environment.
- NixOS-WSL for the Windows target.
- Make recipes with shell commands for bootstrap and recovery workflows.
- GitHub Actions for flake evaluation and native x86_64 WSL builds.
- Lua for the Neovim configuration.

GitHub's language bar reflects the files in a repository, not a required NixOS
technology stack. Languages or tools from another configuration should only be
added when the configuration genuinely uses them.

## Common workflow questions

### How do local web applications work?

Use the VM's IP address from macOS and make the development server listen on
`0.0.0.0`, not only `127.0.0.1`. The Docker module currently opens TCP ports
`5173` and `8787` in the VM firewall.

### How do I access macOS files?

VMware shared folders are mounted at `/host`. Their ownership is forced to the
numeric UID and GID `1000`; adjust the mount if the account IDs change.

### Why must the repository be cloned to `~/nixos-config`?

Home Manager creates an out-of-store Neovim symlink to
`~/nixos-config/users/muhammad/nvim`. Cloning elsewhere leaves that symlink
pointing at a path that does not exist.

## VM setup

The automated bootstrap targets the current VMware Fusion layout. Before
starting, create an ARM64 NixOS VM with UEFI boot, a SATA disk, accelerated
graphics, shared networking, and folder sharing enabled. The default disk is
`/dev/sda`.

> [!CAUTION]
> `make vm/bootstrap0` repartitions and formats the entire device selected by
> `NIXBLOCKDEVICE`. Confirm the device inside the installer before running it.
> A VM snapshot before bootstrap is strongly recommended.

The local SSH identity defaults to `~/.ssh/id_ed25519_nixos_vm`. Boot the NixOS
installer, make the root account reachable over SSH, determine the VM's IP
address, and set the bootstrap variables on macOS:

```sh
export NIXADDR=192.168.0.100
export NIXPORT=22
export NIXNAME=vm-aarch64
export NIXBLOCKDEVICE=sda
```

Run `make` without a target to display the available commands. Perform the
destructive first stage explicitly:

```sh
make vm/bootstrap0
```

This creates the EFI, root, and swap partitions, installs a minimal bootstrap
configuration, enables SSH, and reboots.

The second stage restores SSH and GPG data from an external archive. The archive
is a plain, unencrypted `tar.gz`; keep it outside the repository and only use it
on a trusted network. To create it at the default location expected by
`vm/bootstrap`:

```sh
mkdir -p "$HOME/nixos-secrets"
make SECRETS_ARCHIVE="$HOME/nixos-secrets/backup.tar.gz" secrets/backup
```

After the first reboot, apply the full configuration:

```sh
make vm/bootstrap
```

That command repairs DNS, copies the repository to `/nix-config`, activates
`vm-aarch64`, restores the external archive for the normal user, and reboots.
After the second reboot, clone the normal working copy at the path expected by
Home Manager:

```sh
make vm/repo
```

## Day-to-day changes

Work from `~/nixos-config` inside the VM or WSL. Format and evaluate before
activation:

```sh
nix fmt
nix flake check --all-systems --no-build
nixos-rebuild build --flake .#vm-aarch64
sudo nixos-rebuild test --flake .#vm-aarch64
sudo nixos-rebuild switch --flake .#vm-aarch64
```

The `build` step creates the system closure without activating it.
`nixos-rebuild test` then activates the candidate configuration without making
it the default boot entry. Use `switch` after the test succeeds. On WSL, select
`.#wsl` instead.

## First Zig program

Zig and its language server, ZLS, are installed by Home Manager from the same
pinned `nixpkgs` revision. After applying the configuration, start a project:

```sh
mkdir -p ~/code/zig/hello-world
cd ~/code/zig/hello-world
zig init
nvim src/main.zig
```

Neovim starts ZLS automatically for `.zig` files. Run `:LspInfo` in Neovim to
confirm that `zls` is attached. Build and run the generated example with:

```sh
zig build run
zig build test
```

Do not install ZLS through `:Mason`: Nix manages the single shared compiler and
language-server version for both the VM and WSL.

When adding a new file, stage it before evaluating the local Git flake so Nix can
see it:

```sh
git add path/to/new-file.nix
```

If an activated VM generation is bad, select an older generation from the boot
menu or roll back from a working shell:

```sh
sudo nixos-rebuild switch --rollback
```

## WSL setup

The two currently supported WSL build paths use x86_64 Linux. The local Make
target deliberately rejects other host architectures:

1. Run the **Build NixOS WSL image** workflow in GitHub Actions and download the
   `nixos-wsl-x86_64` artifact.
2. On an x86_64 Linux host, run:

   ```sh
   make wsl
   ```

Import the resulting `nixos.wsl` archive from PowerShell:

```powershell
wsl --import NixOS C:\WSL\NixOS .\nixos.wsl
wsl -d NixOS
```

Clone this repository to `/home/muhammad/nixos-config` in WSL so the Neovim
symlink resolves correctly.

## Maintenance

Update pinned inputs deliberately:

```sh
nix flake update
git diff -- flake.lock
nix flake check --all-systems --no-build
```

After an input update, follow the non-activating `nixos-rebuild build` step for
the target host before testing and switching.

To update only selected inputs with current Nix releases:

```sh
nix flake update nixpkgs home-manager nixos-wsl
```

Commit `flake.lock`; do not edit it manually. Review upstream release notes before
switching NixOS or Home Manager release branches.

`system.stateVersion` and `home.stateVersion` are compatibility baselines, not
package versions. Do not bump them during normal upgrades unless the relevant
release notes require a deliberate migration.

GitHub Actions performs a no-build flake check on relevant pushes and pull
requests. The WSL workflow additionally performs a native x86_64 image build.

## Security and machine assumptions

This configuration currently makes development-VM tradeoffs that are unsuitable
for a multi-user or untrusted machine:

- the public repository contains a password hash, which can be attacked offline;
- the `wheel` user has passwordless sudo;
- Docker group membership is effectively root-equivalent;
- VM bootstrap disables SSH host-key verification and temporarily permits root
  login with a simple bootstrap password;
- the SSH/GPG backup archive is not encrypted;
- the VM assumes `/dev/sda`, interface `enp2s0`, UID/GID `1000`, and the exact
  repository path described above.

These choices are documented rather than silently changed because changing them
would alter the current operating workflow. Secret management, stronger SSH host
verification, and guarded disk provisioning should be handled as separate,
reviewable improvements.

## Growing the configuration

Keep future changes proportional to a real requirement:

1. Put host facts in `machines/` and reusable behavior in `modules/`, grouped by
   concern.
2. Keep user-level programs and dotfiles in the Home Manager module.
3. Add a flake input only when a host or module consumes it.
4. Prefer explicit imports while the repository is small enough to read in one
   pass.
5. Format, evaluate, test, and inspect the diff before switching.

That keeps the repository useful as a learning system today and leaves a clear
path for additional hosts, modules, or a future `nix-darwin` configuration when
they are actually needed.

## References

- [NixOS manual: writing NixOS modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [nix.dev: the Nix module system](https://nix.dev/tutorials/module-system/)
- [Nix manual: flake lock files](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-flake.html#lock-files)
- [Home Manager manual](https://nix-community.github.io/home-manager/)
- [NixOS-WSL documentation](https://nix-community.github.io/NixOS-WSL/)
