Role Name
=========

The pxe_bootloader_setup role installs the Secure Boot PXE chain (signed `shimx64.efi` -> signed `grubx64.efi`) into the TFTP root. This is one-time, bastion-wide infrastructure -- it doesn't depend on `cluster_name` and only needs to run once per bastion, before the first `deploy_pxe_boot_media.yaml` run for any cluster.

It's a separate role/playbook from deploy_pxe_boot_media on purpose, mirroring the same split as create_agent_install_media vs deploy_pxe_boot_media: one-time bastion-wide setup vs. per-cluster, run-every-time work.

Why shim, and why the RPM binaries specifically
-------------------------------------------------

The nodes enforce UEFI Secure Boot. Shim is a small Red Hat-signed bootloader that satisfies Secure Boot's initial trust check and then chainloads a next-stage loader -- in this case, grubx64.efi, also Red Hat-signed. Both binaries are copied as-is from their RPMs.

Shim looks for its next-stage loader (grubx64.efi) in the same directory it was loaded from, so both files are copied directly into the TFTP root.

Requirements
------------

- The bastion must already have `tftp-server` installed (see `bastion_setup.yaml`).

Role Variables
--------------

- `tftp_root` (default `/var/lib/tftpboot`), `shim_src_path`/`grub_src_path` (default `/boot/efi/EFI/redhat/{shimx64,grubx64}.efi`, where the `shim-x64`/`grub2-efi-x64` RPMs install them on RHEL9) -- see `defaults/main.yml`.

Example Playbook
----------------

```yaml
- name: One-time PXE bootloader setup
  hosts: localhost
  connection: local
  become: true

  roles:
    - pxe_bootloader_setup
```

```bash
ansible-playbook playbooks/pxe_bootloader_setup.yaml
```
