NIXADDR ?=
NIXPORT ?= 22
NIXNAME ?= vm-aarch64
NIXUSER ?= muhammad

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SECRETS_ARCHIVE ?= $(MAKEFILE_DIR)/backup.tar.gz

SSH_OPTIONS := \
	-i ~/.ssh/id_ed25519_nixos_vm \
	-o UserKnownHostsFile=/dev/null \
	-o StrictHostKeyChecking=no

.PHONY: vm/bootstrap0

vm/bootstrap0:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted /dev/sda -- mklabel gpt; \
		parted /dev/sda -- mkpart primary 512MB -8GB; \
		parted /dev/sda -- mkpart primary linux-swap -8GB 100%; \
		parted /dev/sda -- mkpart ESP fat32 1MB 512MB; \
		parted /dev/sda -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/sda1; \
		mkswap -L swap /dev/sda2; \
		mkfs.fat -F 32 -n boot /dev/sda3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.settings.experimental-features = [ \"nix-command\" \"flakes\" ];\n \
			services.openssh.enable = true;\n \
			services.openssh.settings.PasswordAuthentication = true;\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && reboot; \
	"

.PHONY: vm/bootstrap vm/copy vm/switch vm/secrets

# Полная начальная загрузка после bootstrap0.
vm/bootstrap:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	$(MAKE) vm/secrets
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) "sudo reboot"

# Копирование конфигурации с Mac в VM.
vm/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='.git/' \
		--exclude='backup.tar.gz' \
		--rsync-path="sudo rsync" \
		./ $(NIXUSER)@$(NIXADDR):/nix-config

# Применение скопированной flake-конфигурации.
vm/switch:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo nixos-rebuild switch --flake \"/nix-config#$(NIXNAME)\" \
	"

# Копирование SSH/GPG-секретов с Mac в готовую VM.
vm/secrets:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='environment' \
		$(HOME)/.ssh/ $(NIXUSER)@$(NIXADDR):~/.ssh
	@if [ -d "$(HOME)/.gnupg" ]; then \
		rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
			--exclude='.#*' \
			--exclude='S.*' \
			--exclude='*.conf' \
			$(HOME)/.gnupg/ $(NIXUSER)@$(NIXADDR):~/.gnupg; \
	fi

.PHONY: secrets/backup secrets/restore

# Локальная резервная копия SSH-ключей и GPG keyring.
secrets/backup:
	mkdir -p $(HOME)/.ssh $(HOME)/.gnupg
	tar -czvf $(SECRETS_ARCHIVE) \
		-C $(HOME) \
		--exclude='.ssh/environment' \
		--exclude='.gnupg/.#*' \
		--exclude='.gnupg/S.*' \
		--exclude='.gnupg/*.conf' \
		.ssh/ \
		.gnupg

# Восстановление секретов на исходной машине перед vm/bootstrap.
secrets/restore:
	@if [ ! -f "$(SECRETS_ARCHIVE)" ]; then \
		echo "Error: $(SECRETS_ARCHIVE) not found"; \
		exit 1; \
	fi
	mkdir -p $(HOME)/.ssh $(HOME)/.gnupg
	tar -xzvf $(SECRETS_ARCHIVE) -C $(HOME)
	find $(HOME)/.ssh -type d -exec chmod 700 {} \;
	find $(HOME)/.ssh -type f -exec chmod 600 {} \;
	find $(HOME)/.gnupg -type d -exec chmod 700 {} \;
	find $(HOME)/.gnupg -type f -exec chmod 600 {} \;
