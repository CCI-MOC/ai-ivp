# Storage Device Wipe

Use these commands to thoroughly wipe a storage device. This can be used to erase the boot disk of an OpenShift node that you plan to reinstall, which avoids certain issues at install time.

## Why wipe before reinstalling

- **Boot disk (general precaution, less certain):** `coreos-installer` overwrites the target disk directly rather than skipping based on existing content, so this is less deterministic than the etcd case above. But leftover LVM/RAID/filesystem signatures in space the new install doesn't happen to overwrite can occasionally confuse the storage stack during boot, and a stale GPT backup header at the end of the disk can in principle cause a tool to "recover" the old, wrong partition table. Wiping removes that risk even though we don't have a confirmed instance of it causing a failure in this pipeline specifically.
- **Etcd disk:** our `98-master-var-lib-etcd.j2` MachineConfig only formats the etcd disk if `/dev/disk/by-partlabel/etcd` doesn't already exist (`ConditionPathExists=!/dev/disk/by-partlabel/etcd`). If a partition with that label survives from a previous install attempt, the formatting step silently skips itself on the next install with no error -- exactly what happened the first time this cluster was installed, leaving an unformatted, unmounted etcd disk. Wiping the disk removes the GPT and its partition labels, which is what makes the condition true again.

## Getting a shell to run these from

- If you're wiping the node's *current* boot/OS disk, you can't safely run this against the disk your OS is actively running from. Boot an alternate environment first -- see [Booting from a RHEL ISO to investigate an OpenShift node](README_SSH_TO_EMPTY_NODE.md).
- If you're wiping a secondary, non-root disk while the node's OS keeps running normally (e.g. the etcd disk), no alternate boot is needed -- a normal shell works fine, e.g. `oc debug node/<hostname> -- chroot /host`. This also works on the etcd disk of an otherwise-still-running cluster you're about to reinstall, since nothing is mounted there to disrupt.

*#WARNING: These commands wipe the system. Be careful where you run them.

1. Confirm you are wiping the right device

If reinstalling, wipe **both** the boot disk and the etcd disk on each node -- run the steps below once per disk. See [Verifying group_vars against a live cluster](README_VERIFY_GROUP_VARS.md) for the `lsblk -o NAME,SIZE,MOUNTPOINT,SERIAL,WWN` command to identify which physical device matches `master{N}_install_drive_serial` (boot) and `master{N}_etcd_drive_wwn` (etcd) in `playbooks/group_vars/<cluster_name>/vars.yml`.

```
lsblk -f # Check the partitions and device size
```

2. Wipe the storage device
```
## NOTE: replace sdX with the device you found in the first step.
wipefs -af /dev/sdX
sgdisk --zap-all /dev/sdX
dd if=/dev/zero of=/dev/sdX bs=1M count=200 status=progress # Wipe beginning of disk
DISK_SIZE_MB=$(( $(blockdev --getsize64 /dev/sdX) / 1024 / 1024 ))
dd if=/dev/zero of=/dev/sdX bs=1M seek=$((DISK_SIZE_MB - 200)) count=200 status=progress # Wipe end of disk
blkdiscard -f /dev/sdX || true # Tell SSD everything is free
```

3. Verification
```
lsblk -f /dev/sdX # Again to make sure it's clean
sgdisk --print /dev/sdX # Make sure no partitions
```
## To Wipe both drives
1. There is a image that will wipe all drives on the system. **BE CAREFUL** Once started this process is automatic and can not be stopped. 

2. Using iDRAC mount the ISO called
   ```
   rhel-9-autowipe.iso
   ```
3. After the image loads either wait 60 seconds or go
   ```
   Troubleings -> Repair a Linux Install
   ```
   A count down will start (10 seconds) before all drives are wiped and the system will shutdown. 
   

