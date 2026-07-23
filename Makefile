NIXADDR ?=
NIXPORT ?= 22
NIXNAME ?= vm-aarch64
NIXUSER ?= muhammad
NIXBLOCKDEVICE ?= sda

REPO_HTTPS_URL ?= https://github.com/thenerdface/nixos-config.git
REPO_SSH_URL ?= git@github.com:thenerdface/nixos-config.git

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SECRETS_ARCHIVE ?= $(MAKEFILE_DIR)/backup.tar.gz
VM_SECRETS_ARCHIVE ?= $(HOME)/nixos-secrets/backup.tar.gz

SSH_OPTIONS := \
	-i ~/.ssh/id_ed25519_nixos_vm \
	-o UserKnownHostsFile=/dev/null \
	-o StrictHostKeyChecking=no

.PHONY: vm/bootstrap0

vm/bootstrap0:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted /dev/$(NIXBLOCKDEVICE) -- mklabel gpt; \
		parted /dev/$(NIXBLOCKDEVICE) -- mkpart primary 512MB -8GB; \
		parted /dev/$(NIXBLOCKDEVICE) -- mkpart primary linux-swap -8GB 100%; \
		parted /dev/$(NIXBLOCKDEVICE) -- mkpart ESP fat32 1MB 512MB; \
		parted /dev/$(NIXBLOCKDEVICE) -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/$(NIXBLOCKDEVICE)1; \
		mkswap -L swap /dev/$(NIXBLOCKDEVICE)2; \
		mkfs.fat -F 32 -n boot /dev/$(NIXBLOCKDEVICE)3; \
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

.PHONY: vm/bootstrap vm/copy vm/switch vm/secrets vm/repo

# Полная начальная загрузка после bootstrap0.
vm/bootstrap:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	$(MAKE) vm/secrets
	$(MAKE) vm/repo
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) "sudo reboot"

# Копирование конфигурации с Mac в VM для первоначальной сборки.
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

# Восстановление SSH/GPG-секретов из внешнего архива на Mac.
vm/secrets:
	@if [ ! -f "$(VM_SECRETS_ARCHIVE)" ]; then \
		echo "Error: $(VM_SECRETS_ARCHIVE) not found"; \
		exit 1; \
	fi
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		$(VM_SECRETS_ARCHIVE) \
		$(NIXUSER)@$(NIXADDR):/tmp/nixos-secrets.tar.gz
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		set -eu; \
		umask 077; \
		mkdir -p ~/.ssh ~/.gnupg; \
		tar -xzf /tmp/nixos-secrets.tar.gz -C ~; \
		find ~/.ssh -type d -exec chmod 700 {} \;; \
		find ~/.ssh -type f -exec chmod 600 {} \;; \
		find ~/.gnupg -type d -exec chmod 700 {} \;; \
		find ~/.gnupg -type f -exec chmod 600 {} \;; \
		rm -f /tmp/nixos-secrets.tar.gz; \
	"

# Клонирование рабочего репозитория внутрь новой VM.
# Это наша автоматизация шага, который Хашимото после bootstrap делает внутри VM.
vm/repo:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		set -eu; \
		if [ -d ~/nixos-config/.git ]; then \
			git -C ~/nixos-config pull --ff-only; \
		else \
			git clone $(REPO_HTTPS_URL) ~/nixos-config; \
			git -C ~/nixos-config remote set-url origin $(REPO_SSH_URL); \
		fi; \
	"

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
