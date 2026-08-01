#
# ZoobaProto v2 - Makefile
# iOS Tweak: Bearer Token Dumper for Zooba
#

THEOS := /opt/theos
THEOS_DEVICE_IP := localhost
THEOS_DEVICE_PORT := 2222

# Package Info
PACKAGE_VERSION := 2.0.0
PKG_NAME := ZoobaProto
PKG_BUNDLEID := com.zoobaproto.tokenDumper
PKG_DESCRIPTION := Zooba Bearer Token Dumper - Extract auth tokens from Wildlife/Pitaya
PKG_MAINTAINER := ZoobaProto
PKG_AUTHOR := ZoobaProto
PKG_SECTION := Tweaks
PKG_DEPENDS := mobilesubstrate (>= 0.9.5000)

# Target
TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
INSTALL_TARGET_PROCESSES := Zooba

# Files
MODULES_DIR := src/modules
HOOKS_DIR := src/hooks

# Core Modules
CORE_FILES := $(wildcard $(MODULES_DIR)/core/*.mm) $(wildcard $(MODULES_DIR)/core/*.m)
NETWORK_FILES := $(wildcard $(MODULES_DIR)/network/*.mm) $(wildcard $(MODULES_DIR)/network/*.m)
STORAGE_FILES := $(wildcard $(MODULES_DIR)/storage/*.mm) $(wildcard $(MODULES_DIR)/storage/*.m)
UTILS_FILES := $(wildcard $(MODULES_DIR)/utils/*.mm) $(wildcard $(MODULES_DIR)/utils/*.m)

# Hooks
HOOK_FILES := $(wildcard $(HOOKS_DIR)/*.mm) $(wildcard $(HOOKS_DIR)/*.m)

# Config
CONFIG_FILES := $(wildcard src/config/*.mm) $(wildcard src/config/*.m)

# All source files
ZOOBAPROTO_FILES := src/main.mm \
                   $(CONFIG_FILES) \
                   $(HOOK_FILES) \
                   $(CORE_FILES) \
                   $(NETWORK_FILES) \
                   $(STORAGE_FILES) \
                   $(UTILS_FILES)

# Frameworks
ZOOBAPROTO_FRAMEWORKS := Foundation UIKit Security
ZOOBAPROTO_PRIVATE_FRAMEWORKS :=

# Flags
ZOOBAPROTO_CFLAGS := -fobjc-arc -w -DDEBUG=$(DEBUG)
ZOOBAPROTO_LDFLAGS := -Wl,-dead_strip

# Include Theos
include $(THEOS)/makefiles/common.mk

TWEAK_NAME := ZoobaProto
ZoobaProto_FILES := $(ZOOBAPROTO_FILES)
ZoobaProto_FRAMEWORKS := $(ZOOBAPROTO_FRAMEWORKS)
ZoobaProto_PRIVATE_FRAMEWORKS := $(ZOOBAPROTO_PRIVATE_FRAMEWORKS)
ZoobaProto_CFLAGS := $(ZOOBAPROTO_CFLAGS)
ZoobaProto_LDFLAGS := $(ZOOBAPROTO_LDFLAGS)

# Install
INSTALL_TARGET_PROCESSES := Zooba

include $(THEOS)/makefiles/tweak.mk

# ===== Custom Targets =====

.PHONY: clean-all rebuild install-all debug logs

# Clean all build artifacts
clean-all:
	@echo "Cleaning all build artifacts..."
	@rm -rf obj/ packages/ .theos/ *.deb

# Rebuild from scratch
rebuild: clean-all $(THEOS_MAKE_PARALLEL) all

# Install and open logs
install-all: install
	@echo "Installing tweak and opening logs..."
	@ssh root@$(THEOS_DEVICE_IP) -p $(THEOS_DEVICE_PORT) "tail -f /var/log/syslog | grep ZoobaProto"

# View live logs
logs:
	@ssh root@$(THEOS_DEVICE_IP) -p $(THEOS_DEVICE_PORT) "tail -f /var/log/syslog | grep ZoobaProto"

# Open SSH session
ssh-device:
	@ssh root@$(THEOS_DEVICE_IP) -p $(THEOS_DEVICE_PORT)

# Package info
info:
	@echo "ZoobaProto v$(PACKAGE_VERSION)"
	@echo "Bundle ID: $(PKG_BUNDLEID)"
	@echo "Target: $(TARGET)"
	@echo "Architectures: $(ARCHS)"
	@echo "Files: $(words $(ZOOBAPROTO_FILES)) source files"

# Development helpers
dev:
	@echo "Development Mode"
	@echo "1. make: Build tweak"
	@echo "2. make install: Install to device"
	@echo "3. make logs: View live logs"
	@echo "4. make ssh-device: SSH to device"
