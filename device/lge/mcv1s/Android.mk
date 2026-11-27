LOCAL_PATH := $(call my-dir)
ifeq ($(TARGET_DEVICE),mcv1s)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
