# chroot_img_builder

The goal of this project is to be able to customize existing raspbian image
with custom scripts, using chroot. One objective is to be able to create
custom images from a running raspberry pi (or any ARM based computer), with
minimal requirements.

## Installation

### Linux

First, install the requirements on the computer that will build the image:

```shell
apt get -y kpartx wget unzip git
```

Second, clone the current repository:

```shell
git clone https://github.com/badock/chroot_img_builder.git
```

## Running the scripts

From the `chroot_img_builder` folder, run the following command as a super-user:

```shell
bash build_with_chroot.sh
```

It will take approximately 30 minutes to build a image. At the end, a new `result.img` 
image should have been produced.

## Flashing an image on an SD card

You can use [https://www.balena.io/etcher/](https://www.balena.io/etcher/) to
flash the `result.img` on an SD card. *Be aware that it will erase the content of the SD card*.

## Contact

If there is a problem or a bug, feel free to open an issue!