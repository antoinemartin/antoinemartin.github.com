+++
title = "Unlock and Root a Nexus Device"
date = "2012-10-25"
slug = "2012/10/25/unlock-and-root-a-nexus-device"
Categories = ["Development", "Android"]
Tags = ["old", "obsolete", "android", "linux", "adb", "root"]
[toc]
enable = false
+++

Having an unlocked and rooted device provides several advantages :

- Easy backup and restore with Nandroid backup,
- Easy firmware replacement and updates installation,
- Advanced debugging capabilities.

The following instructions allow unlocking and rooting a Nexus device (Galaxy
Nexus, Nexus 7) from the command line on a Linux machine. It involves:

- Backuping your device,
- Unlocking the bootloader,
- Restoring the backup,
- Rooting the device.

<!-- More -->

### Prerequisites

Here is the list of prerequisites :

- [Android SDK](http://developer.android.com/sdk/index.html), to have access
    to `adb` and `fastboot`.
- [Clockwork Mode (CWM)](http://download2.clockworkmod.com/recoveries/recovery-clockwork-6.0.1.0-grouper.img)
    recovery image.
- [SuperSU](http://download.chainfire.eu/212/SuperSU/CWM-SuperSU-v0.96.zip)
    installable zip.

The `platform-tools` directory of the Android SDK must be on your `PATH`, and
the device must have USB debugging enabled.

### Udev rules

On Linux, you don't have to install any driver. You need however to enable
access for your users. Depending on your distribution, you may have a package
handling that, but if not, here is a quick way to give access to your user to
the device (here `antoine`). Type as `root`:

```sh
[root@dev ~] $ cd /etc/udev/rules.d
[root@dev rules.d] $ wget https://raw.github.com/M0Rf30/android-udev-rules/master/51-android.rules
[root@dev rules.d] $ groupadd adbusers
[root@dev rules.d] $ udevadm control --reload-rules
[root@dev rules.d] $ gpasswd -a antoine adbusers
```

Plug your device on the USB cable, and you should be able to see it with `adb`:

```sh
[antoine@dev nexus] $ adb devices
List of devices attached
015d2ebecd341e06        device
```

### Backup

Unlocking the bootloader wipes all the data on the device. If you're not doing
this on a new device, you may want to backup and restore your data and
applications. With the device connected in USB debug mode, type :

```sh
[antoine@dev nexus] $ adb backup -apk -shared -all -f backup.ab
```

Depending on the amount of data you have on your device, this process can be
quite long.

### OEM unlock

Unlocking the device is easy. With the device connected in USB debug mode, type:

```sh
[antoine@dev nexus] $ adb reboot bootloader
```

The device will reboot in _fastboot_ mode. To check this, type:

```sh
[antoine@dev nexus] $ fastboot devices
015d2ebecd341e06        fastboot
```

You will see your device in the list. Then you can unlock it by typing:

```sh
[antoine@dev nexus] $ fastboot oem unlock
...
(bootloader) erasing userdata...
(bootloader) erasing userdata done
(bootloader) erasing cache...
(bootloader) erasing cache done
(bootloader) unlocking...
(bootloader) Bootloader is unlocked now.
OKAY [ 54.821s]
finished. total time: 54.821s
[antoine@dev nexus] $ fastboot reboot
```

At the end of the process, reboot your device:

```sh
[antoine@dev nexus] $ fastboot reboot
```

You will go through the initialization process in the device.

### Restore

Once the device is up and running, you can restore your data with:

```sh
[antoine@dev nexus] $ adb restore backup.ab
```

### Root

To root the device, we will apply the SuperSU installable zip as an update in
CWM.

First we push the SuperSU installable zip in the device filesystem:

```sh
[antoine@dev nexus] $ adb push CWM-SuperSU-v0.96.zip /sdcard/update.zip
752 KB/s (674673 bytes in 0.875s)
```

Now that the device is unlocked, we can boot it into CWM. We first reboot it in
fastboot mode:

```sh
[antoine@dev nexus] $ adb reboot bootloader
```

And then boot it with CWM:

```sh
[antoine@dev nexus] $ fastboot boot recovery-clockwork-6.0.1.0-grouper.img
downloading 'boot.img'...
OKAY [  0.800s]
booting...
OKAY [  0.020s]
finished. total time: 0.820s
```

After a few seconds, the device will show the CWM interface. With the volume
buttons, move to the `install zip from sdcard` option and select it by pushing
the power button.

On the new menu that appears, choose the `apply /sdcard/update.zip` option and
scroll down to the `Yes` option. click on the power button and SuperSU will be
installed.

Once done, you can go back to the main CWM menu and reboot the device.

### Permanently install CWM

You can permanently install CWM on the device recovery partition so that you can
start your device in CWM without being connected via USB.

Your device automatically restores the recovery partition at each boot. To avoid
that, you need to delete the `/system/recovery-from-boot.p` file on the device :

```sh
[antoine@dev nexus] $ adb shell
shell@android:/ $ su
shell@android:/ # rm /system/recovery-from-boot.p
shell@android:/ # exit
shell@android:/ $ exit
```

You can then reboot in fastboot mode and install CWM permanently :

```sh
[antoine@dev nexus] $ adb reboot bootloader
[antoine@dev nexus] $ fastboot flash recovery recovery-clockwork-touch-6.0.0.6-grouper.img
[antoine@dev nexus] $ fastboot reboot
```

I personally don't recommend to install CWM permanently as it will prevent you
from installing the OTA updates that are pushed to your device.
