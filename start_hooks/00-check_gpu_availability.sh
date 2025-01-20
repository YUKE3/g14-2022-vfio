#!/bin/sh

DRI_PATH="pci-0000:03:00.0"

if fuser -s /dev/dri/by-path/$DRI_PATH-card || fuser -s /dev/dri/by-path/$DRI_PATH-render ; then
  echo "gpu in use"
  exit 1
fi

exit 0
