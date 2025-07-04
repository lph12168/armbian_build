# Rockchip RK3588S octa core 4/8/16GB RAM SoC GBE USB3 WiFi/BT NVMe eMMC
BOARD_NAME="Orange Pi 5 Pro"
BOARDFAMILY="rockchip-rk3588"
BOARD_MAINTAINER=""
BOOTCONFIG="orangepi_5_pro_defconfig" # vendor name, not standard, see hook below, set BOOT_SOC below to compensate
BOOTCONFIG_SATA="orangepi_5_pro_sata_defconfig"
BOOT_SOC="rk3588"
KERNEL_TARGET="vendor"
FULL_DESKTOP="yes"
BOOT_LOGO="desktop"
BOOT_FDT_FILE="rockchip/rk3588s-orangepi-5-pro.dtb"
BOOT_SCENARIO="spl-blobs"
BOOT_SUPPORT_SPI="yes"
BOOT_SPI_RKSPI_LOADER="yes"
IMAGE_PARTITION_TABLE="gpt"
KERNEL_UPGRADE_FREEZE="vendor-rk35xx@24.8.1"
DEFAULT_OVERLAYS="panthor-gpu"

function post_family_tweaks__orangepi5pro_naming_audios() {
	display_alert "$BOARD" "Renaming orangepi5pro audios" "info"

	mkdir -p $SDCARD/etc/udev/rules.d/
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi0-sound", ENV{SOUND_DESCRIPTION}="HDMI0 Audio"' > $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-dp0-sound", ENV{SOUND_DESCRIPTION}="DP0 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-es8388-sound", ENV{SOUND_DESCRIPTION}="ES8388 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules

	return 0
}

function post_family_config_branch_vendor__orangepi5pro_uboot_add_sata_target() {
	display_alert "$BOARD" "Configuring ($BOARD) standard and sata uboot target map" "info"
	# Note: whitespace/newlines are significant; BOOT_SUPPORT_SPI & BOOT_SPI_RKSPI_LOADER influence the postprocess step that runs for _every_ target and produces rkspi_loader.img
	UBOOT_TARGET_MAP="BL31=$RKBIN_DIR/$BL31_BLOB $BOOTCONFIG spl/u-boot-spl.bin u-boot.dtb u-boot.itb;;idbloader.img u-boot.itb rkspi_loader.img
	BL31=$RKBIN_DIR/$BL31_BLOB $BOOTCONFIG_SATA spl/u-boot-spl.bin u-boot.dtb u-boot.itb;; rkspi_loader_sata.img"
}

function post_uboot_custom_postprocess__create_sata_spi_image() {
	display_alert "$BOARD" "Create rkspi_loader_sata.img" "info"

	dd if=/dev/zero of=rkspi_loader_sata.img bs=1M count=0 seek=16
	/sbin/parted -s rkspi_loader_sata.img mklabel gpt
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart idbloader 64 7167
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart vnvm 7168 7679
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart reserved_space 7680 8063
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart reserved1 8064 8127
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart uboot_env 8128 8191
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart reserved2 8192 16383
	/sbin/parted -s rkspi_loader_sata.img unit s mkpart uboot 16384 32734
	dd if=idbloader.img of=rkspi_loader_sata.img seek=64 conv=notrunc
	dd if=u-boot.itb of=rkspi_loader_sata.img seek=16384 conv=notrunc
}

# Override family config for this board; let's avoid conditionals in family config.
function post_family_config__orangepi5pro_use_vendor_uboot() {
	BOOTSOURCE='https://github.com/orangepi-xunlong/u-boot-orangepi.git'
	BOOTBRANCH='branch:v2017.09-rk3588'
	BOOTPATCHDIR="legacy"
}
