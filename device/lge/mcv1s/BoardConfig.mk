LOCAL_PATH := device/lge/mcv1s
ALLOW_MISSING_DEPENDENCIES := true

# Stock recovery userspace is 32-bit ARM
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a53
TARGET_BOARD_PLATFORM := mt6750
TARGET_BOOTLOADER_BOARD_NAME := mcv1s
TARGET_NO_BOOTLOADER := true

# Values read from the stock recovery header
TARGET_PREBUILT_KERNEL := $(LOCAL_PATH)/prebuilt/zImage-dtb
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,32N2 androidboot.hardware=mcv1s buildvariant=user
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00008000 --ramdisk_offset 0x05000000 --second_offset 0x00f00000 --tags_offset 0x04000000

# Size of the dumped recovery file
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 22020096
BOARD_HAS_NO_REAL_SDCARD := true
BOARD_FLASH_BLOCK_SIZE := 131072
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_SUPPRESS_SECURE_ERASE := true

# TWRP, trimmed to fit the small ramdisk budget
TW_THEME := portrait_hdpi
RECOVERY_SDCARD_ON_DATA := true
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 120
TW_EXCLUDE_SUPERSU := true
TW_EXCLUDE_TWRPAPP := true
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
TW_EXTRA_LANGUAGES := false
TW_INCLUDE_NTFS_3G := false
TW_NO_EXFAT_FUSE := true
