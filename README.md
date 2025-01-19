# g14-2022-vfio
This repos contains my (loose) steps that I've taken for setting up a GPU passthrough setup on my laptop. The hook scripts I've used is also contained within this repo.

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