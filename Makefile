#
# ZoobaProto v2 - Makefile
# iOS Tweak: Bearer Token Dumper for Zooba
#

THEOS ?= /workspace/theos
THEOS_DEVICE_IP := localhost
THEOS_DEVICE_PORT := 2222

# Package Info
PACKAGE_VERSION := 2.1.0
PKG_NAME := ZoobaProto
PKG_BUNDLEID := com.zoobaproto.tokenDumper
PKG_DESCRIPTION := Zooba ProtoBuf Interceptor - Capture Pitaya/Protobuf traffic
PKG_MAINTAINER := ZoobaProto
PKG_AUTHOR := ZoobaProto
PKG_SECTION := Tweaks
PKG_DEPENDS := mobilesubstrate (>= 0.9.5000)

# Target
TARGET := iphone:clang:latest:15.0
ARCHS := arm64
INSTALL_TARGET_PROCESSES := Zooba

# Cross-compilation settings for Linux host
export PATH := /tmp/arm64-tools/bin:/tmp/lld-19-extract/usr/bin:$(PATH)
export LD_LIBRARY_PATH := /tmp/lld-19-extract/usr/lib/llvm-19:/tmp/ncurses-fix/lib/x86_64-linux-gnu:/tmp/ios-arm64e-clang-toolchain/lib:$(LD_LIBRARY_PATH)

# Override theos toolchain for Linux cross-compilation
TARGET_CC := arm64-apple-darwin-clang
TARGET_CXX := arm64-apple-darwin-clang++
TARGET_LD := arm64-apple-darwin-ld

# iOS SDK settings
THEOS_SDKS_PATH := $(THEOS)/sdks
THEOS_PLATFORM_SDK_ROOT := $(THEOS)/sdks/iPhoneOS15.6.sdk

# Files
MODULES_DIR := src/modules
HOOKS_DIR := src/hooks

# Core Modules
CORE_FILES := $(wildcard $(MODULES_DIR)/core/*.mm) $(wildcard $(MODULES_DIR)/core/*.m)
NETWORK_FILES := $(wildcard $(MODULES_DIR)/network/*.mm) $(wildcard $(MODULES_DIR)/network/*.m)
STORAGE_FILES := $(wildcard $(MODULES_DIR)/storage/*.mm) $(wildcard $(MODULES_DIR)/storage/*.m)
UTILS_FILES := $(wildcard $(MODULES_DIR)/utils/*.mm) $(wildcard $(MODULES_DIR)/utils/*.m)
UI_FILES := $(wildcard $(MODULES_DIR)/ui/*.mm) $(wildcard $(MODULES_DIR)/ui/*.m)
PROTO_FILES := $(wildcard $(MODULES_DIR)/proto/*.mm) $(wildcard $(MODULES_DIR)/proto/*.m)
PROTO_INTERCEPTOR_FILES := $(wildcard $(MODULES_DIR)/protointerceptor/*.mm) $(wildcard $(MODULES_DIR)/protointerceptor/*.m)
PROTO_UI_FILES := $(wildcard $(MODULES_DIR)/ui/ProtoUI.mm)

# Hooks
HOOK_FILES := $(wildcard $(HOOKS_DIR)/*.mm) $(wildcard $(HOOKS_DIR)/*.m)
SWIZZLER_FILES := $(wildcard $(HOOKS_DIR)/Swizzler.mm) $(wildcard $(HOOKS_DIR)/Swizzler.m)

# Config
CONFIG_FILES := $(wildcard src/config/*.mm) $(wildcard src/config/*.m)

# All source files
ZOOBAPROTO_FILES := src/main.mm \
                   $(CONFIG_FILES) \
                   $(SWIZZLER_FILES) \
                   $(HOOK_FILES) \
                   $(CORE_FILES) \
                   $(NETWORK_FILES) \
                   $(STORAGE_FILES) \
                   $(UTILS_FILES) \
                   $(UI_FILES) \
                   $(PROTO_UI_FILES) \
                   $(PROTO_FILES) \
                   $(PROTO_INTERCEPTOR_FILES)

# Frameworks
ZOOBAPROTO_FRAMEWORKS := Foundation UIKit Security
ZOOBAPROTO_PRIVATE_FRAMEWORKS :=

# External Libraries - fishhook for C function hooking
ZOOBAPROTO_LDFLAGS := -Wl,-dead_strip -lfishhook

# Flags
ZOOBAPROTO_CFLAGS := -fobjc-arc -w -DDEBUG=$(DEBUG) \
    -I/workspace/project/Jk/src \
    -I/workspace/project/Jk/src/config \
    -I/workspace/project/Jk/src/modules/core \
    -I/workspace/project/Jk/src/modules/network \
    -I/workspace/project/Jk/src/modules/storage \
    -I/workspace/project/Jk/src/modules/utils \
    -I/workspace/project/Jk/src/modules/ui \
    -I/workspace/project/Jk/src/modules/proto \
    -I/workspace/project/Jk/src/modules/protointerceptor \
    -I/workspace/project/Jk/src/hooks

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
	@echo "=========================================="
	@echo "  ZoobaProto v$(PACKAGE_VERSION)"
	@echo "=========================================="
	@echo "Bundle ID:     $(PKG_BUNDLEID)"
	@echo "Target:        $(TARGET)"
	@echo "Architectures: $(ARCHS)"
	@echo "Source Files:  $(words $(ZOOBAPROTO_FILES))"
	@echo ""
	@echo "Modules:"
	@echo "  - Core:      $(words $(CORE_FILES)) files"
	@echo "  - Network:   $(words $(NETWORK_FILES)) files"
	@echo "  - Storage:   $(words $(STORAGE_FILES)) files"
	@echo "  - Utils:     $(words $(UTILS_FILES)) files"
	@echo "  - UI:        $(words $(UI_FILES)) files"
	@echo "  - Hooks:     $(words $(HOOK_FILES)) files"
	@echo "  - Config:    $(words $(CONFIG_FILES)) files"
	@echo "=========================================="

# Development helpers
dev:
	@echo "=========================================="
	@echo "  ZoobaProto Development Mode"
	@echo "=========================================="
	@echo "1. make         - Build tweak"
	@echo "2. make install - Install to device"
	@echo "3. make logs    - View live logs"
	@echo "4. make ssh     - SSH to device"
	@echo "5. make info    - Show project info"
	@echo "6. make clean   - Clean build artifacts"
	@echo "=========================================="
