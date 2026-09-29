TARGET := iphone:clang:10.3:7.0
ARCHS = armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FMODFix
EAFMODFix_FILES = FMODThreadFix.x
EAFMODFix_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
