# Storage Device Wipe

Use these commands to thoroughly wipe a storage device. This can be used to erase the boot disk of an OpenShift node that you plan to reinstall, which avoids certain issues at install time.

*#WARNING: These commands wipe the system. Be careful where you run them.

1. Confirm you are wiping the right device
lsblk -f # Check the partitions and device size

2. Wipe the storage device
## NOTE: replace sdX with the device you found in the first step
sudo -i
wipefs -af /dev/sdX
sgdisk --zap-all /dev/sdX
dd if=/dev/zero of=/dev/sdX bs=1M count=200 status=progress # Wipe beginning of disk
dd if=/dev/zero of=/dev/sdX bs=1M seek=-200 count=200 status=progress # Wipe end of disk
blkdiscard -f /dev/sdX || true # Tell SSD everything is free

3. Verification
lsblk -f /dev/sdX # Again to make sure it's clean
sgdisk --print /dev/sdX # Make sure no partitions

