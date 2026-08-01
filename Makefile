export THEOS = /workspace/theos
export PATH := /tmp/arm64-tools/bin:/tmp/lld-19-extract/usr/bin:$(PATH)
export LD_LIBRARY_PATH := /tmp/lld-19-extract/usr/lib/llvm-19:/tmp/ncurses-fix/lib/x86_64-linux-gnu:/tmp/ios-arm64e-clang-toolchain/lib:$(LD_LIBRARY_PATH)

ARCHS = arm64

TARGET_CC := arm64-apple-darwin-clang
TARGET_CXX := arm64-apple-darwin-clang++
TARGET_LD := arm64-apple-darwin-ld

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TestOverlay
$(TWEAK_NAME)_FILES = tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit
$(TWEAK_NAME)_INSTALL_TARGET_PROCESSES = Zooba

include $(THEOS)/makefiles/tweak.mk
