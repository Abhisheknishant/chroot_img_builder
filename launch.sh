#!/usr/bin/bash

echo "PoC of customizing a raspbian image"

RASPI_IMG="./2020-02-13-raspbian-buster-lite.img"
RASPI_WORK_IMG="./result.img"

RASPI_IMG_URL="https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip"
KERNEL_IMG_URL="https://raw.githubusercontent.com/dhruvvyas90/qemu-rpi-kernel/master/kernel-qemu-4.4.34-jessie"


############################
# FUNCTIONS
############################


############################
# CUSTOMIZE THE Boot partition
############################
if [ -d boot_partition ]; then
    rm -rf boot_partition
fi

if [ ! -f kernel.img ]; then
  wget $KERNEL_IMG_URL -O kernel.img -o logs_download_kernel.log
fi

if [ ! -f $RASPI_IMG ]; then
  wget $RASPI_IMG_URL -O raspi_image.img.zip -o logs_download_raspbian.log
  unzip raspi_image.img.zip
  mv *raspbian*.img $RASPI_IMG
fi

mkdir boot_partition
cp $RASPI_IMG $RASPI_WORK_IMG

qemu-img resize $RASPI_WORK_IMG 5G

############################
# Exit QEMU VM
############################
qemu-system-arm \
    -kernel kernel.img \
    -cpu arm1176 \
    -m 256 \
    -machine versatilepb \
    -append "root=/dev/sda2 panic=1 rootfstype=ext4 rw" \
    -drive "file=$RASPI_WORK_IMG,index=0,media=disk,format=raw" \
    -serial stdio \
    -net nic -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::22280-:80 \
    -no-reboot \

############################
# Exit QEMU VM
############################

exit 0
