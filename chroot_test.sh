#!/bin/bash

# This script allows you to chroot ("work on") 
# the raspbian sd card as if it's the raspberry pi
# on your Ubuntu desktop/laptop
# just much faster and more convenient

# credits: https://gist.github.com/jkullick/9b02c2061fbdf4a6c4e8a78f1312a689

# make sure you have issued
# (sudo) apt install qemu qemu-user-static binfmt-support

# Write the raspbian image onto the sd card,
# boot the pi with the card once 
# so it expands the fs automatically
# then plug back to your laptop/desktop
# and chroot to it with this script.

# Invoke:
# (sudo) ./chroot-to-pi.sh /dev/sdb 
# assuming /dev/sdb is your sd-card
# if you don't know, when you plug the card in, type:
# dmesg | tail -n30 


# Note: If you have an image file instead of the sd card, 
# you will need to issue 
# (sudo) apt install kpartx
# (sudo) kpartx -v -a 2017-11-29-raspbian-stretch-lite.img
# then
# (sudo) ./chroot-to-pi.sh /dev/mapper/loop0p
# With the vanilla image, you have very little space to work on
# I have not figured out a reliable way to resize it
# Something like this should work, but it didn't in my experience
# https://gist.github.com/htruong/0271d84ae81ee1d301293d126a5ad716
# so it's better just to let the pi resize the partitions

mkdir -p /mnt/raspbian

qemu-img resize result.img 5G

sudo losetup /dev/loop1 result.img
sudo kpartx -av /dev/loop1

parted /dev/loop1 resizepart 2 4500
e2fsck -f /dev/mapper/loop1p2
resize2fs /dev/mapper/loop1p2

sleep 3

# unmount loop device
kpartx -d /dev/loop1
kpartx -v -d result.img
losetup -d /dev/loop1

echo "TAG -- 1"


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
#cp /usr/bin/qemu-arm-static /mnt/raspbian/usr/bin/

echo "You will be transferred to the bash shell now."
echo "Issue 'exit' when you are done."
echo "Issue 'su pi' if you need to work as the user pi."

# Add the "templates" folder to the root partition
rsync -avz --progress templates/ /mnt/raspbian/templates/

# chroot to raspbian
chroot /mnt/raspbian /bin/bash /templates/prepare.sh
chroot /mnt/raspbian /bin/bash /templates/install.sh

# ----------------------------
# Clean up
# revert ld.so.preload fix
sed -i 's/^#CHROOT //g' /mnt/raspbian/etc/ld.so.preload

# unmount everything
umount /mnt/raspbian/{dev/pts,dev,sys,proc,boot,}


echo "Shrinking result.img"
path_to_executable=$(which pishrink.sh)
if [ ! -x "$path_to_executable" ] ; then
    wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
    mv pishrink.sh /usr/bin/.
    chmod +x /usr/bin/pishrink.sh
fi

pishrink.sh result.img

exit 0