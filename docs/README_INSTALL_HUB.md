# Instructions to install a Hub cluster

## Background
* See this link for background information on what the Agent-Iso is and how it works
https://www.redhat.com/en/blog/meet-the-new-agent-based-openshift-installer-1

## Prerequisites

1. The IP for the bastion server. See [Environment Details](/docs/ENVIRONMENT.md)
2. SSH access to the bastion server.
3. Bastion server must be provisioned following the instructions in [the main readme](/README.md). This will install required dependencies like the openshift installer binary.
4. You need the storage device details and MAC addresses for each node. For existing environments, these are already in `playbooks/group_vars/<cluster_name>/vars.yml`. You can also check [Environment Details](/docs/ENVIRONMENT.md). For new environments ask the person who installed the hardware, or use the instructions below under Gathering Prerequisite Information to gather the information yourself. 
5. Ability to clone the https://github.com/CCI-MOC/ai-ivp/ project on the bastion. This may require permissions in GitHub. 
6. VNC access to the bastion, to get a desktop with a browser for the iDRAC virtual console. This is required because these iDRACs can't be managed with `racadm` from a FIPS-enabled bastion, so mounting the install ISO has to go through the iDRAC web GUI in a browser.

## Instructions

1. SSH into the bastion server
```
ssh your_user@bastion_ip
```

Perform all of the following instructions on the bastion server unless the instructions say otherwise.

2. Clone the https://github.com/CCI-MOC/ai-ivp/ project into your home directory.
```
cd ~
git clone https://github.com/CCI-MOC/ai-ivp/
cd ai-ivp/
```

3. Ansible configuration to generate an install ISO

This process uses the OpenShift Agent Based Installer method. You will generate an ISO to boot each server from, which will kick off the install.

Each cluster's values (hostnames, MACs, IPs, network config, storage devices, SSH public key) are tracked in an Ansible inventory under `playbooks/group_vars/<cluster_name>/vars.yml` — one file per cluster (currently `infra` and `staging`). You select which cluster to build for with `-e cluster_name=infra` or `-e cluster_name=staging` in the next step; there's no per-run vars file to hand-edit anymore.

The one value that's actually sensitive is the Red Hat pull secret. It's kept out of git entirely.

- The first time you use a given cluster on this bastion, copy the schema template and fill in the real value:
  ```
  cp playbooks/group_vars/<cluster_name>/secrets.yaml.example playbooks/group_vars/<cluster_name>/secrets.yaml
  ```
  ```yaml
  pull_secret: <pull secret to download from Redhat Repo>
  ```
  `secrets.yaml` is gitignored — it's local to this bastion checkout and never committed.
- If a cluster's hardware changes (new hostnames/IPs/MACs/drives), edit `playbooks/group_vars/<cluster_name>/vars.yml` directly. It's a tracked file, so changes are versioned and don't need to be redone on every ISO build.

4. Generate an OpenShift install ISO using Ansible

`cluster_name` must match one of the clusters defined in `playbooks/inventory.yml` (currently `infra` or `staging`) — it selects which `group_vars` to build with.
  ```
  ansible-playbook playbooks/create_agent_iso.yaml -e "cluster_name=infra"
  ```
- Every run starts by wiping any previous output for that cluster, so there's no stale data left over from a prior/failed run.
- The ISO is present at `playbooks/output/<cluster_name>/work/agent.x86_64.iso` and the kubeconfig/kubeadmin credentials are in `playbooks/output/<cluster_name>/work/auth/`.

5. Open an iDRAC session for each node you want to install on

VNC into the bastion to get a desktop with a browser.

Open the iDRAC web console for each server you will install OpenShift on. Get the iDRAC IPs from [Environment Details](/docs/ENVIRONMENT.md).

- Open Chrome (click the red fedora icon to the top left of the desktop and type 'Chrome', then select the option).
- WARNING: Do *NOT* use Firefox. It will complain about TLS related issues with no easy way to accept the risk and continue.
- In Chrome, use tabs to open the iDRAC web console for each server you will install OpenShift on. Just enter the IP address into the browser bar.
- When it complains about TLS, go to Advanced -> Accept.
- Enter your iDRAC username and password. The person who installed the servers for you may have helped you set this up. For a prototype environment it may be the default iDRAC username and password, which are root/calvin.

Then, in each browser tab, open the virtual console:

- Select "Launch" on the right side of the screen, under "Virtual Console Preview".
- The first time you do this for each node, you will be prompted about popups being blocked. Do this:
  - Click the popup icon in the top right of the window
  - Change the radio button for "Always allow popups..."
  - Select "Done"
  - Close the popup window
  - Select "Launch" again
- Another popup about SSL may display briefly. Wait and it will disappear.
- Another orange screen may appear briefly. Wait and it will disappear.

6. Attach the ISO

- *IMPORTANT: DO NOT CLOSE THE BROWSER UNTIL CoreOS IS INSTALLED!!* Closing the window before that (which takes a long time), will cause the install to fail. If this happens, reboot the server, which will restart the long-running install process.
- Select "Connect Virtual Media"
- Under "Map CD/DVD", select "Choose File"
- Select the installation .iso file. It's the one you just generated, at `playbooks/output/<cluster_name>/work/agent.x86_64.iso` on the bastion.
- Select "Map Device"
- Confirm the bar at the top of the virtual console says "Virtual Media is connected", and "Devices Mapped: 1" and lists the name of your .iso file.
- Close the Virtual Media popup.

7. Reboot the server to begin the install

- From the iDRAC console for the node, power cycle the server.
- Switch back to the Virtual Console popup.
- Watch the top of the screen as the machine boots. There is a progress bar at the bottom, and a Dell symbol to the top left.
- Press the "Keyboard" button at the top of the window to bring up a virtual keyboard. Use this instead of your physical keyboard for the steps. You have to quickly press keys, and the input from your physical keyboard can sometimes be delayed in this interface.
- When the bar is approximately one third full, some text will appear to the right of the Dell symbol. As soon as that text appears option appears, quickly press `F11`.
- Close the virtual keyboard popup.
- You will see the text change to "Entering Boot Manager" with blue highlighting. Wait a minute.
- Select "One-shot UEFI Boot Menu"
- Select "Virtual Optical Drive"
- Confirm the selection

8. Monitor the install from the bastion

- `<installation_directory>` below is `playbooks/output/<cluster_name>/work` -- the same `cluster_name` you used in the `ansible-playbook` command in step 4. E.g. for `-e "cluster_name=infra"`, that's `playbooks/output/infra/work`.
  ```
  openshift-install agent wait-for bootstrap-complete --dir <installation_directory>
  ```
  This command will block and wait until the initial control plane is up and the temporary bootstrap process has pivoted to the permanent control plane nodes. It is safe to run this immediately after booting your nodes.
  ```
  openshift-install agent wait-for install-complete --dir <installation_directory>
  ```
  Once the bootstrap is complete, run this command. It will wait until all cluster operators are available, the worker nodes have joined, and the cluster is fully operational.

9. Troubleshooting

**NOTE:** The install will appear to sit idle at various points, including one point where it displays a login prompt which will go away on its own. Be patient. If it looks like it is not progressing, wait at least 30 minutes before assuming it is broken.

**NOTE:** The Common Installation Errors section below lists the symptoms and resolutions of commonly encountered issues.

Once the install has progressed to the point that there is an OS running on the node and it is running an SSH daemon, you can ssh in to troubleshoot.

Use the private key that correspons to the public key that you provided when you generated the ISO.

Use the IP of the node that you provided in the installer file. Do not use the iDRAC IP.

```
ssh -i /root/ssh/id_rsa_ocp core@<node IP>
```

### Post-Openshift Install Setup

- These steps must be performed after the OpenShift cluster install is complete, before Autoshift can be installed.
- `playbooks/post_install_setup.yaml` is a general playbook intended to eventually automate this whole section. Right now it only covers step 1 below -- steps 2, 3, 7, and 8 are still manual, as described further down.
  1. Pre-configure the required secrets.

     This is automated via `playbooks/post_install_setup.yaml`, which creates the `cert-manager` and `portworx` namespaces and the `github-client-secret`, `px-pure-secret`, and `aws-route53-credentials` secrets described below. It's idempotent (safe to re-run) and pulls its sensitive values from an ansible-vault-encrypted file rather than a Secrets Manager.

     - The first time you use a given cluster, copy the schema template and fill in real values:
       ```
       cp playbooks/vault/examples/post_install_secrets.yaml.example playbooks/vault/<cluster_name>/post_install_secrets.yaml
       ansible-vault encrypt playbooks/vault/<cluster_name>/post_install_secrets.yaml
       ```
       See the file for the exact fields needed: GitHub OAuth app client ID/secret/teams, and AWS access key ID/secret access key for Route53.
     - `pure.json` is different -- it's provided as-is by the storage admin, so there's no YAML to fill in. Just drop their file in place and encrypt it:
       ```
       cp <the pure.json the storage admin gave you> playbooks/vault/<cluster_name>/pure.json
       ansible-vault encrypt playbooks/vault/<cluster_name>/pure.json
       ```
     - Run the playbook (prompts for the vault password; no vault password file is used or stored anywhere in this repo):
       ```
       ansible-playbook playbooks/post_install_setup.yaml -e "cluster_name=infra" --ask-vault-pass
       ```
     - To change values later, edit with `ansible-vault edit playbooks/vault/<cluster_name>/post_install_secrets.yaml` (or `pure.json`) and re-run the playbook.

     `commonName`, `dnsNames`, and `issuer-name` on the `aws-route53-credentials` secret aren't stored anywhere -- they're derived automatically from `cluster_name`/`base_domain` (e.g. `*.apps.infra.ocp.massopen.cloud`, `letsencrypt-route53-infra`).

   2. Install the nmstate operator
      Since before Portworx can communicate with the flash blade servers we need to have some Network Setup configure first. We only need a default nmstate instance so that the CRD resource type can be created.
	  - Manually install the Nmstate Operator from the Openshift Software Catelog. You can find it on the left side of the Console under Ecosystem -> Software Catalog
	  - Search for "Nmstate" and click on "Kubernetes NMState Operator". 
	  - Choose all the default settings and install
	  - After the Nmstate operator is installed go to it, click on the NMState tab, and create a default instanace of NMState (you do not have to fill out anything). 
	  - Apply the follwing files using oc apply -f <filename> after downloading them to a local machine. Files are also located under ai-ivp/install
           *Note:* These values work for both staging and infra because they have the same networking for portworx.
	  - Run the following commands to apply the required files:
	  
		**`AdminNetworkPolicy.yaml`**
	   ```
		oc apply -f ai-ivp/install/AdminNetworkPolicy.yaml
	   ```
		
	   and
	   
	   **`NodeNetworkConfigurationPolicy.yaml`**
	   ```
		oc apply -f ai-ivp/install/NodeNetworkConfigurationPolicy.yaml
	   ```
	  
	  
   3. Install portworx
     In order to install Autoshift we need the ability to create storage. Install and setting up Portworx will give our cluster access to storage on demand. 
	 - Manually install the Potworx Operator from the Openshift Software Catalog. You can find it on the left side of the Console under Ecosystem -> Software Catalog
	 - Search for "Portworx" and click on "Portworx Enterprise Operator".  Click on Install
	 - **Change the namespace location to "portworx"**. You can keep all other options to default. 
	 - After installing go to Ecosystem -> Installed Operators -> Portworx Enterprise. Select "All Projects" on the upper Left-Center to check everwhere. 
	 - Click on the StorageCluster Tab and create a new StorageCluster. File is located under ai-ivp/install
       *Note:* Thes values work for both staging and infra.
	 - The StorageCluster can also be added by running the following command:
	 
	   **`StorageCluster.yaml`**
	   ```
	    oc apply -f ai-ivp/install/StorageCluster.yaml
	   ```
	   
	 Watch the events to monitor the the Portworx installation. 
    - After the portworx is done installing we need to create our new storage class that uses portworx. 

      From the OpenShift Console go to:
	  Storage -> StorageClasses and click on the blue Create StorageClass button on the upper right. 
	  Apply the following file that will set Portworx as the default storage class. File is located under ai-ivp/install
	- The StorageClass can also be added by running the following command:
	
	  **`StorageClass.yaml`**
	  ```
	   oc apply -f ai-ivp/install/StorageClass.yaml    
	  ```
	  
7. Install Autoshift
 
   Follow the instructions and requirements to install Autoshift here:  https://github.com/auto-shift/autoshiftv2/blob/main/docs/quickstart.md
   For Step 4 this is a example of Application File to create and apply. A sample is located under ai-ivp/install:
   
   **`Application.yaml`**
   ```
    oc apply -f ai-ivp/install/Application.yaml
	```
	The location of all our clusterset files is located here: https://github.com/CCI-MOC/ai-ivp/tree/feature/staging-standalone/autoshift/values/clustersets
	PLEASE NOTE: We are currently using hub-minimal.yaml. For autoshift this file is referenced as hub (line 21 in hub-minimal.yaml)
	After Autoshift is installed apply the clusterset file (in our case hub-minimal) to the localcluster.
	```
	oc label managedcluster local-cluster cluster.open-cluster-management.io/clusterset=hub --overwrite
	```
	Once this is applied AutoShift will now be managing the cluster. To check the status of the cluster you can log into ArgoCD. 
	
	- The Route for ArgoCD can be found under Network -> Routes in the openshift-gitops namespace. 
	To find the admin password for ArgoCD go to Workload -> Secrets and check in the infra-gitops-cluster secret in the openshift-gitops namespace. 

8. Adding Users

For each user that wants to login using GitHub, add them to the appropiate role. The GitHub login process will create a User object with a name that is the same as their github username.

For example, to give a user Cluster-Admin access, run:

```
oc adm policy add-cluster-role-to-user cluster-admin <your-github-username>
```
 
## Common Installation Errors

* If the installation hangs, wait and the terminal for one of the nodes being installed displays:
```
INFO <hostname> updated status from preparing-for-installation to preparing-successful (Host finished successfully to prepare for installation)
```
The likely cause is that the CoreOS instance being used by the installer is not using FIPS.

You can confirm whether this is the problem by sshing into the problematic node, and running `sudo journalctl -u assisted-service.service --no-pager`.

If this is the problem, you wil see the following message:
```
level=error msg=failed to fetch Master Machines: failed to load asset \"Install Config\": failed to create install config: invalid \"install-config.yaml\" file: fips: Forbidden: target cluster is in FIPS mode, use the FIPS-capable installer binary for RHEL 9 on a host with FIPS enabled.\nlevel=erro <TRUNCATED>: exit status 3" go-id=87918 pkg=cluster-state request_id=
It was created using openshift-install-fips AND on a system with FIPS enabled.
```
To fix this, reboot the node and press (TBD key) to enter the egrub menu. Then append ` fips=1` to the line that starts with the `linux` command. This should be the second line deisplayed. It is a long line with multiple options. Then continue the boot.

## Gathering Prerequisite Information

### Re-verifying values before reinstalling an existing cluster

If a cluster is already installed and you're about to wipe it for a reinstall, see [Verifying group_vars against a live cluster](README_VERIFY_GROUP_VARS.md) to confirm `playbooks/group_vars/<cluster_name>/vars.yml` still matches live state first -- once the nodes are wiped, you lose the ability to check.

Also wipe **both** the boot disk and the etcd disk on each node before reinstalling -- see [Storage Device Wipe](README_STORAGE_WIPE.md). Briefly: leftover partition state from the previous install can make our own MachineConfigs silently skip work they should redo, and can generally confuse the OS installer on the boot disk.

### Gathering the storage device names for each node

*NOTE: For existing environments, these are documented in [Environment Details](/docs/ENVIRONMENT.md)

If the node is being reinstalled and already has CoreOS on it, you can ssh in as the `core` user. Otherwise, the node has no OS yet, so follow [Booting from a RHEL ISO to investigate an OpenShift node](/docs/README_SSH_TO_EMPTY_NODE.md) to get a shell.

From a shell on each OpenShift node, run:

```
lsblk -o NAME,SIZE,SERIAL,WWN
```

Look at the size column. Two devices will have a size of 186.3G -- one will be the OpenShift boot drive, the other dedicated as storage for this cluster's etcd.

- For the **boot drive**, note its `SERIAL` -- this goes in `master{N}_install_drive_serial` in `playbooks/group_vars/<cluster_name>/vars.yml`.
- For the **etcd drive**, note its `WWN` instead -- this one is matched by hostname in `98-master-var-lib-etcd.j2` rather than `rootDeviceHints`, so goes in `master{N}_etcd_drive_wwn`. **Must be quoted** (e.g. `"0x55cd2e414db91779"`) -- an unquoted `0x...` value gets parsed as a hex integer by YAML, and Jinja renders it back out in decimal.

