# g14-2022-vfio
This repos contains my steps that I've taken for setting up a GPU passthrough setup on my laptop. The hook scripts I've used is also contained within this repo.

Follow along on this guide as well for any unclear steps: [asus-linux.org guide](https://asus-linux.org/guides/vfio-guide/)


# Device info
ASUS ROG Zephyrus G14(2022) GA402RJ

BIOS Version 319
(If you have a older BIOS you may have a better time)

Fedora Kionite 41

# TODO

- Add performance hooks scripts
- Add dgpu_exec scripts for dGPU isolation
- looking-glass selinux bypass
- looking-glass kvmfr setup

# Table of Contents

1. [Preparations](#preparations)
2. [Creating Windows VM](#create-the-windows-vm)
3. [Setup VM with passthrough](#setup-the-vm-with-passthrough)
4. [Freezing Issues](#freezing-issues)
    1. [PCIe Port PM issue](#pcie-port-power-manager)
    2. [AMDGPU Reattach issue / Isolating the dGPU](#amdgpu-driver-issue-isolating-the-gpu)
5. [References](#references)

# Preparations

### Install necessary packages:

```bash
rpm-ostree install libvirt qemu-kvm-core virt-manager
```

### Disable SELinux (optional, workaround in later section):

`/etc/libvirt/qemu.conf`, uncomment this line and set to 0:

```
#security_default_confined = 1
```

### Enable XML Editing in virt-manager

`Edit > Preferences > Enable XML Editing`

![Virt Manager Image](images/XML_Editing.png)

### Disabling Resizable BAR

This feature causes a code 43 error when the GPU is passthrough to the VM. You could disable it using [Smokeless_UMAF](https://github.com/DavidS95/Smokeless_UMAF/tree/main) tool. (Do this at your own risk)

There is also a workaround script in this repo if you want to leave this feature enabled. Personally, I don't see a measurable performance impact with this feature disabled.

### Download Windows and VirtIO ISOs:

[VirtIO Stable](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

[Windows ISO](https://massgrave.dev/windows_11_links)


# Create the Windows VM

Use Virt Manager to create a new VM, make sure on Step 5, choose `Customize configuration before install`.

![VM Creation Option](images/Customize_config.png)

Here's what needs to be changed:

- Disk 1 should have `Disk bus` set to `VirtIO`.
- A SATA CDROM for VirtIO ISO should be added with `Add Hardware -> Storage -> CDROM Device`.
- Network NIC should have `Device model` set to `virtio`.

### Setting the CPU topology and enable hyperthreading

This will significantly speed up the installation time if you are using more than a single core.

![CPU Menu](images/CPU_config.png)

Then, click on the `XML` tab and add: 

`<feature policy="require" name="topoext"/>`

under the CPU tags:

![CPU XML](images/CPU_xml.png)

### Windows Install Process

Go through the rest of install as usual, you can set `Time and currency format` to `English (world)` to avoid some bloatware.

When you reach the drive selection screen, click on `Load Driver` and choose the folder `virtio-win/amd64/win11`. You can also install the internet driver at the same time. Though you can install the driver later in device manager (and skip Windows account login). The driver is in the folder `NetKVM/w11/amd64`.

Then you can continue the Windows install as normal.

When you get to Windows Account login, choose Work or School, and choose Domain join to avoid Microsoft Account login (may not work, Microsoft is forcing online accounts, SkipOOBE method already don't work on latest iso)

### Debloat

I used to debloat my Windows installs a lot (Used Windows 10 LTSC before, then used Tiny11 and AtlasOS in VMs). However, I found that the performance gained is pretty neglible, especially since we already have overhead with VM. If the goal is best performance, Dual Booting would be better. Therefore, I just use the [Chris Titus Tech's Windows Utility](https://github.com/ChrisTitusTech/winutil).


# Setup the VM with passthrough

I recommend cloning the original VM (without cloning the drive) so that you still have a easy way to boot the VM without GPU passthrough.

### Add PCI hardware

`Add Hardware -> PCI Host Device`

`0000:03:00:00` and `0000:03:00:01` should be added for GPU passthough.

(optional) `0000:07:00:04` can be added for the two USB A ports on the right side of the laptop.

### Add a temporary mouse

`Add Hardware -> USB Host Device`. Just for now to install display drivers, as the SPICE mouse will be very hard to use once the display driver loads.

### Before booting, we need to run the following scripts to make sure GPU passthrough works

`fix_rebar.sh` - Fixes Code 43 (only if you did not disable resizable bar), only needs to be ran once per boot.

```bash
#!/bin/sh

VFIO_DEVICE="0000:03:00.0"
echo -n ${VFIO_DEVICE} > /sys/bus/pci/drivers/amdgpu/unbind
echo 8 > /sys/bus/pci/devices/${VFIO_DEVICE}/resource0_resize
echo 1 > /sys/bus/pci/devices/${VFIO_DEVICE}/resource2_resize
```

`check_gpu_available.sh` - Checks if the GPU is currently being used by an application.

```bash
#!/bin/sh

DRI_PATH="pci-0000:03:00.0"

if fuser -s /dev/dri/by-path/$DRI_PATH-card || fuser -s /dev/dri/by-path/$DRI_PATH-render ; then
  echo "gpu in use"
  exit 1
fi

exit 0
```

Run `check_gpu_available.sh` before running the VM to make sure the dGPU is available. We can add these to libvirt hooks to automate it later.

### Boot VM, run Windows update to get drivers.

You should be able to find the GPU in the device manager afterwards.

You can turn off the VM now and we can finish setting it up.

### Remove unnecessary things

- Sound ich9
- Console 1
- Channel Spice (only if you don't use looking-glass)
- USB Redirectors
- Edit the VM's XML and find `memballon model="virtio"`. Replace `virtio` with `none`.
- Remove CDROMs

### VM hooks

Follow the instruction here on [Asus-linux guide for libvirt hooks](https://asus-linux.org/guides/vfio-guide/#chapter-2-libvirt-hooks).

Make sure that you use the correct VM names.

Then, add the necessary scripts in start_hooks and end_hooks folders to `/etc/libvirt/hooks/qemu.d/$vmname/prepare/begin/*` and `/etc/libvirt/hooks/qemu.d/$vmname/prepare/begin/*` respectively.

### Finishing up

Set `Video QXL` model to `None`. You can now use this VM by connecting an external monitor to the HDMI port and pass through USB mouse and keyboard.

If you want to setup looking-glass: See [Asus-linux looking-glass Guide](https://asus-linux.org/guides/vfio-guide/#option-3-looking-glass-setup)

I also have [section]() on some looking glass setup for Fedora Kinoite specially.

If you want to share keyboard and mouse with linux host: See [Asus-linux evdev Guide](https://asus-linux.org/guides/vfio-guide/#option-2-evdev-input)


# Freezing Issues

When you start/stop the VM, you may experience the entire linux display stack crashing (and sometimes recovering). This is caused by two things: The laptop's pcie port power manager and amdgpu drivers.

### PCIe Port Power Manager

This issue could be fixed by adding this kernel parameter:

`pcie_port_pm=off`

However, this kernel parameter makes my laptop completely unusable as a portable device, as this parameter causes:

- dGPU to never to go D3Sleep, 20-30W on idle :(. You could keep a VM running in the background so that dGPU goes to sleep in the VM, however, the battery drain is still going too high for a portable device.

- Sleep completely breaks my machine for some reason.

Instead of the kernel parameter, you could try to use the following script to turn off power management for the dGPU only. This has the same downsides as above, but they only start after you run the script. 

```bash
VFIO_DEVICE="0000:03:00.0"
VFIO_AUDIO_DEVICE="0000:03:00.1"

sudo sh -c "echo 'on' > /sys/bus/pci/devices/${VFIO_DEVICE}/power/control"
sudo sh -c "echo 'on' > /sys/bus/pci/devices/${VFIO_AUDIO_DEVICE}/power/control"
```

### amdgpu driver issue (isolating the GPU)

If you detach the GPU while there is a process running on it, the amdgpu driver is left in a bad state, and when the dGPU reattaches after the VM shutsdown, the amdgpu stack completely crashes. You need to make sure that no process is using the GPU when you boot up the VM. This can be done manually, but many software (especially electron apps) claims the GPU for no reason.

Instead, we can completely isolate the GPU by assigning limiting it to be used by a specific group.

Create a `passthru` group:

```
sudo groupadd passthru
```

Add this udev rule:
`/etc/udev/rules.d/72-passthrough.rules`
```
KERNEL=="card[0-9]", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", ATTRS{boot_vga}=="0", GROUP="passthru", TAG="nothing", ENV{ID_SEAT}="none"
KERNEL=="renderD12[0-9]", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", ATTRS{boot_vga}=="0", GROUP="passthru", MODE="0660"
```

Reboot the laptop, you can check if it worked by running the command `ll /dev/dri`. The expected output looks like this:

```
drwxr-xr-x. 2 root root          120 Feb 10 06:41 by-path
crw-rw----. 1 root passthru 226,   0 Feb 10 07:17 card0
crw-rw----+ 1 root video    226,   2 Feb 10 06:44 card2
crw-rw----. 1 root passthru 226, 128 Feb 10 06:41 renderD128
crw-rw-rw-. 1 root render   226, 129 Feb 10 00:12 renderD129
```

This prevents any process from running on the dGPU without explicit permission.

# References

* [fluffysheap's reddit post](https://old.reddit.com/r/VFIO/comments/ry4i4d/workaround_for_sysfs_cannot_create_duplicate/) - Isolating dGPU to avoid amdgpu sysfs bug.

* [asus-linux VFIO guide](https://asus-linux.org/guides/vfio-guide/) - In depth VM creation step

* [dixyes's gist](https://gist.github.com/dixyes/740018e040593ef0ec729a784f84f8c7) - Disabling rebar