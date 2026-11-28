DEVICE_PATH := device/lge/mcv1s

# Stock userspace is 32-bit ARM
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a53
TARGET_BOARD_PLATFORM := mt6750
TARGET_BOOTLOADER_BOARD_NAME := mcv1s
TARGET_NO_BOOTLOADER := true

# Only the recovery ramdisk is built. pack.py adds the stock kernel.
TARGET_NO_KERNEL := true
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,32N2 androidboot.hardware=mcv1s buildvariant=user
BOARD_RAMDISK_USE_LZ4 := true
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 22020096
BOARD_FLASH_BLOCK_SIZE := 131072
TARGET_USERIMAGES_USE_EXT4 := true

TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_DENSITY := xhdpi
