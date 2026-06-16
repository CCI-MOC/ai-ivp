Role Name
=========

The create_agent_iso role builds the OpenShift Agent Based Installer ISO from the provided variables.

The role creates an installation directory that contains the disk image and can be used to monitor or debug the installation process, see https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/support/troubleshooting for further details.

The role also creates a backup directory of the installation directory before the 

Requirements
------------

The openshift-install-fips binary needs to be installed and available in the user $PATH.

Download the binary as detailed in https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/installation_overview/installing-fips and copy it to /usr/local/bin.


Role Variables
--------------

Variables for the cluster configuration are contained in vars/main.yaml. The cluster_name variable determines the name of the installation directories.

Dependencies
------------

No other dependencies.

Example Playbook
----------------

The playbook create_agent_iso.yaml that exists in this repo calls the role and creates the installation directory, backup directory, and disk image in accordance with the configurations defined in the variables and templates.

- name: Generate OpenShift Agent Installer Ignition Files
  hosts: localhost
  connection: local

  roles:
    - create_agent_iso

To execute this playbook, optionally defining cluster_name as an extra variable to define the name of the installation directory, run

ansible-playbook create_agent_iso.yaml -e "cluster_name=NAME"

License
-------

BSD

Author Information
------------------

Daniel Groh
Red Hat, Inc.
