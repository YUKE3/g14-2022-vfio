#!/bin/sh

if [ ! -e /tmp/dgpu-rebar-fixed ]
then
    echo "Fixing DGPU rebar status"
    echo -n ${VFIO_DEVICE} > /sys/bus/pci/drivers/amdgpu/unbind
    echo 8 > /sys/bus/pci/devices/${VFIO_DEVICE}/resource0_resize
    echo 1 > /sys/bus/pci/devices/${VFIO_DEVICE}/resource2_resize
    touch /tmp/dgpu-rebar-fixed
fi
