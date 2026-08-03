Role Name
=========

The create_agent_install_media role builds OpenShift Agent Based Installer boot media from the provided variables -- either a bootable ISO (for iDRAC virtual media) or PXE boot files, selected via the `boot_method` variable.

The role creates an installation directory that contains the generated boot media and can be used to monitor or debug the installation process, see https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/support/troubleshooting for further details.

The role also creates a backup directory of the installation directory before the boot media is generated.

Requirements
------------

The openshift-install-fips binary needs to be installed and available in the user $PATH.

Download the binary as detailed in https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/installation_overview/installing-fips and copy it to `/usr/local/bin`.


Role Variables
--------------

Variables for the cluster configuration are contained in `playbooks/group_vars/<cluster_name>/`. The cluster_name variable determines the name of the installation directories.

`boot_method` (default: `iso`) selects the generated boot media: `iso` for a bootable ISO, or `pxe` for PXE boot files (`boot-artifacts/` containing vmlinuz/initrd/rootfs/ipxe). See `defaults/main.yml`.

Dependencies
------------

No other dependencies.

Example Playbook
----------------

The playbook create_agent_install_media.yaml that exists in this repo calls the role and creates the installation directory, backup directory, and boot media in accordance with the configurations defined in the variables and templates.

```yaml
- name: Generate OpenShift Agent Installer boot media
  hosts: localhost
  connection: local

  roles:
    - create_agent_install_media
```

To execute this playbook, optionally defining cluster_name as an extra variable to define the name of the installation directory, and boot_method to choose ISO or PXE, run

```bash
ansible-playbook create_agent_install_media.yaml -e "cluster_name=NAME"
ansible-playbook create_agent_install_media.yaml -e "cluster_name=NAME boot_method=pxe"
```

Author Information
------------------

Daniel Groh
Red Hat, Inc.
