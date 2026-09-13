ARCHS := arm64
# 这里改版本：编译SDK版本:最低部署版本
TARGET := iphone:clang:17.0:15.0

THEOS_DEVICE_IP = localhost
include $(THEOS)/makefiles/common.mk

APP_NAME = CGuiDemo
CGuiDemo_C_FILES = main.c
CGuiDemo_FRAMEWORKS = UIKit Foundation CoreGraphics UIKit

include $(THEOS_MAKE_PATH)/application.mk
