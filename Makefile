obj-m += jdi-drm-enhanced.o
jdi-drm-enhanced-objs += src/main.o src/drm_iface.o src/params_iface.o src/ioctl_iface.o
ccflags-y := -g -std=gnu99 -Wno-declaration-after-statement

dtb-y += jdi-drm-enhanced.dtbo

targets += $(dtbo-y)
always  := $(dtbo-y)

.PHONY: all clean install uninstall

# KERNELRELEASE is set by DKMS, can be different inside chroot
ifeq ($(KERNELRELEASE),)
KERNELRELEASE := $(shell uname -r)
endif
# LINUX_DIR is set by Buildroot
ifeq ($(LINUX_DIR),)
LINUX_DIR := /lib/modules/$(KERNELRELEASE)/build
endif

# BUILD_DIR is set by DKMS, but not if running manually
ifeq ($(BUILD_DIR),)
BUILD_DIR := .
endif

BOOT_CONFIG_LINE := dtoverlay=jdi-drm-enhanced
BOOT_CMDLINE_ADD := console=tty2 fbcon=font:VGA8x8 fbcon=map:10

# Raspbian 12 moved config and cmdline to firmware
ifeq ($(wildcard /boot/firmware/config.txt),)
	CONFIG=/boot/config.txt
else
	CONFIG=/boot/firmware/config.txt
endif
ifeq ($(wildcard /boot/firmware/cmdline.txt),)
	CMDLINE=/boot/cmdline.txt
else
	CMDLINE=/boot/firmware/cmdline.txt
endif


all: jdi-drm-enhanced.dtbo
	$(MAKE) -C '$(LINUX_DIR)' M='$(shell pwd)'

jdi-drm-enhanced.dtbo: jdi-drm-enhanced.dts
	dtc -@ -I dts -O dtb -W no-unit_address_vs_reg -o $@ $<

install_modules:
	$(MAKE) -C '$(LINUX_DIR)' M='$(shell pwd)' modules_install
	# Rebuild dependencies
	depmod -A

install: install_modules install_aux

# Separate rule to be called from DKMS
install_aux: jdi-drm-enhanced.dtbo
	# Install device tree overlay
	install -D -m 0644 $(BUILD_DIR)/jdi-drm-enhanced.dtbo /boot/overlays/
	# Add configuration line if it wasn't already there
	@grep -qxF '$(BOOT_CONFIG_LINE)' $(CONFIG) \
		|| printf '[all]\ndtparam=spi=on\n$(BOOT_CONFIG_LINE)\n' >> $(CONFIG)
	# Add auto-load module line if it wasn't already there
	@grep -qxF 'jdi-drm-enhanced' /etc/modules \
		|| echo 'jdi-drm-enhanced' >> /etc/modules
	# Configure fbcon for display
	@grep -qF '$(BOOT_CMDLINE_ADD)' $(CMDLINE) \
		|| sed -i.save 's/$$/ $(BOOT_CMDLINE_ADD)/' $(CMDLINE)

uninstall:
	# Remove fbcon configuration and create a backup file
	@sed -i.save 's/ $(BOOT_CMDLINE_ADD)//' $(CMDLINE)
	# Remove auto-load module line and create a backup file
	@sed -i.save '/jdi-drm-enhanced/d' /etc/modules
	# Remove configuration line and create a backup file
	@sed -i.save '/$(BOOT_CONFIG_LINE)/d' $(CONFIG)
	# Remove device tree overlay
	@rm -f /boot/overlays/jdi-drm-enhanced.dtbo

clean:
	$(MAKE) -C '$(LINUX_DIR)' M='$(shell pwd)' clean
