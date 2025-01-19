# g14-2022-vfio
This repos contains my steps that I've taken for setting up a GPU passthrough setup on my laptop. The hook scripts I've used is also contained within this repo.

Follow along on this guide as well for any unclear steps: [asus-linux.org guide](https://asus-linux.org/guides/vfio-guide/)


# Device info
ASUS ROG Zephyrus G14(2022) GA402RJ

BIOS Version 319
(If you have a older BIOS you may have a better time)

Fedora Kionite 41


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

### Disabling supergfxctl

`systemctl disable supergfxd`

VFIO mode is redundant when hybrid (default behavior) works completely fine. Supergfxctl also interferes with drivers and other tools (like `driverctl`)


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

![CPU Mneu](images/CPU_config.png)

Then, click on the `XML` tab and add: 

`<feature policy="require" name="topoext"/>`

under the CPU tags:

![CPU XML](images/CPU_xml.png)

### Windows Install Process

Go through the rest of install as usual, you can set `Time and currency format` to `English (world)` to avoid some bloatware.

When you reach the drive selection screen, click on `Load Driver` and choose the folder `virtio-win/amd64/win11`. Also install the internet driver at the same time (can be installe later through device manager), Choose the folder `NetKVM/w11/amd64`.

Then you can continue the Windows install as normal.

### Debloat

I used to debloat my Windows installs alot (Used Windows 10 LTSC before, then used Tiny11 and AtlasOS in VMs). However, I found that the performance gained is pretty neglible, especially since we already have overhead with VM. If the goal is best performance, Dual Booting would be better. Therefore, I just use the [Chris Titus Tech's Windows Utility](https://github.com/ChrisTitusTech/winutil).