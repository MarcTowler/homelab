#!/usr/bin/env bash
set -euo pipefail

# Lets get the Image, currently set to ubuntu 25.04
wget https://cloud-images.ubuntu.com/releases/plucky/release/ubuntu-25.04-server-cloudimg-amd64.img

#Run the qm create command to create a new VM with the inputted ID
VMID=$1

qm create $VMID --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci

#Next set image to the VM
qm set $VMID --scsi0 local-lvm:0,import-from=/root/ubuntu-25.04-server-cloudimg-amd64.img

#Set boot order
qm set $VMID --boot order=scsi0

#Cloud-init time
qm set $VMID --ide2 local-lvm:cloudinit

#Template the VM
qm template $VMID