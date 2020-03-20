#!/bin/bash

set -x

RASPI_IMG="./2020-02-13-raspbian-buster-lite.img"
RASPI_WORK_IMG="./result.img"

RASPI_IMG_URL="https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip"
KERNEL_IMG_URL="https://raw.githubusercontent.com/dhruvvyas90/qemu-rpi-kernel/master/kernel-qemu-4.4.34-jessie"


if [ ! -f kernel.img ]; then
  wget $KERNEL_IMG_URL -O kernel.img -o logs_download_kernel.log
fi

if [ ! -f $RASPI_IMG ]; then
  wget $RASPI_IMG_URL -O raspi_image.img.zip -o logs_download_raspbian.log
  unzip raspi_image.img.zip
  mv *raspbian*.img $RASPI_IMG
fi

cp $RASPI_IMG $RASPI_WORK_IMG

######### BEGIN ##########
# Extend the image by 3gb
dd if=/dev/zero bs=1M count=3092 >> result.img

#do the parted stuff, unmount kpartx, then mount again
kpartx -v -a result.img
sleep 3

LOOP_DEVICE=$(losetup -a | grep -v "(deleted)" | grep "result.img" | sed 's/:.*//g')
LOOP_DEVICE_NAME=$(echo "$LOOP_DEVICE" | sed 's/.*\///g')

partprobe $LOOP_DEVICE

start=$(cat /sys/block/$LOOP_DEVICE_NAME/${LOOP_DEVICE_NAME}p2/start)
end=$(($start+$(cat /sys/block/$LOOP_DEVICE_NAME/${LOOP_DEVICE_NAME}p2/size)))
newend=$(($(cat /sys/block/$LOOP_DEVICE_NAME/size)-8))
size_mbytes=$(( ($newend - $start) * 512 / (1024 * 1024) ))
#size_mbytes

# bash

parted $LOOP_DEVICE resizepart 2  $size_mbytes
# (echo d; echo 2; echo w; echo q) | fdisk -u  $LOOP_DEVICE
# (echo n; echo p; echo 2; echo ; echo ;) | fdisk -u $LOOP_DEVICE

sleep 3

# # unmount loop device
kpartx -d $LOOP_DEVICE
losetup -d $LOOP_DEVICE

# # kpartx -d /dev/loop0

kpartx -v -a result.img
LOOP_DEVICE=$(losetup -a | grep -v "(deleted)" | grep "result.img" | sed 's/:.*//g')
LOOP_DEVICE_NAME=$(echo "$LOOP_DEVICE" | sed 's/.*\///g')

sleep 3

# check file system
e2fsck -f /dev/mapper/${LOOP_DEVICE_NAME}p2
# #expand partition
resize2fs /dev/mapper/${LOOP_DEVICE_NAME}p2

# bash

# unmount loop device
kpartx -d $LOOP_DEVICE
losetup -d $LOOP_DEVICE
######### END ##########

if [ -d  /mnt/raspbian ]; then
    rm -rf /mnt/raspbian
fi
mkdir -p /mnt/raspbian

BOOT_START_SECTOR=$(fdisk -l result.img | grep W95 | awk '{print $2}')
BOOT_START_POSITION=$(($BOOT_START_SECTOR * 512))
ROOT_START_SECTOR=$(fdisk -l result.img | grep Linux | awk '{print $2}')
ROOT_START_POSITION=$(($ROOT_START_SECTOR * 512))
  
  

## mount partition
# mount -o rw ${1}2  /mnt/raspbian
# mount -o rw ${1}1 /mnt/raspbian/boot
mount -o offset=$ROOT_START_POSITION result.img /mnt/raspbian
mount -o offset=$BOOT_START_POSITION result.img /mnt/raspbian/boot



# mount binds
mount --bind /dev /mnt/raspbian/dev/
mount --bind /sys /mnt/raspbian/sys/
mount --bind /proc /mnt/raspbian/proc/
mount --bind /dev/pts /mnt/raspbian/dev/pts

# ld.so.preload fix
#sed -i 's/^/#CHROOT /g' /mnt/raspbian/etc/ld.so.preload

# copy qemu binary
cp /usr/bin/qemu-arm-static /mnt/raspbian/usr/bin/

echo "You will be transferred to the bash shell now."
echo "Issue 'exit' when you are done."
echo "Issue 'su pi' if you need to work as the user pi."

# Add the "templates" folder to the root partition
rsync -avz --progress templates/ /mnt/raspbian/templates/

# chroot to raspbian
chroot /mnt/raspbian df -lh
chroot /mnt/raspbian /bin/bash /templates/prepare.sh
chroot /mnt/raspbian /bin/bash /templates/install.sh
chroot /mnt/raspbian df -lh

# ----------------------------
# Clean up
# revert ld.so.preload fix
#sed -i 's/^#CHROOT //g' /mnt/raspbian/etc/ld.so.preload

# unmount everything
umount /mnt/raspbian/{dev/pts,dev,sys,proc,boot,}

# Shrink the image
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo mv pishrink.sh /usr/local/bin

pishrink.sh result.img

exit 0