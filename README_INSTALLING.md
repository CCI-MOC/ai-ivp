# Instructions to install an "Infra" cluster

## Background
* See this link for background information on what the Agent-Iso is and how it works
https://www.redhat.com/en/blog/meet-the-new-agent-based-openshift-installer-1

## Instructions

### Install OpenShift

1. Make sure you can Login to bastion ( 10.11.0.30 ) using idrac 10.6.1.152. This is so you have access to a GUI and browser. Also make sure you have the ability to scp beteen .20 and .30

2. Verify installer binaries
- Make sure `openshift-install-fips` and `butane` are in the /usr/local/bin directory.

3. Create a user account on the GUI bastion

*TODO:* We should only need one bastion server. We ran into an issue where we needed the GUI desktop to have a browser to mount ISOs (see below). The fastest way to get this was to use a separate server to install an instance of RHEL that has a GUI. In the future we can do the steps below on the same bastion server. We tried at length to mount the ISO in a way that did not require a browser, without success (tried NFS and HTTP mounts). One of these was not supported, the other did not work. We suspect that there is a bug or incompatibility in idrac preventing us from using the other.

- Generate a ssh keypair on .20. `ssh-keygen` and follow the instructions. *Set a passphrase because others will have access to the private key file!*
- An existing administrator on .30 will must to create a user for you on the GUI bastion.30, following the instructions in docs/README_BASTION_ADMINS.md. You will have to provide them with the public key you generated on .20. By default it is at ~/.ssh/id_rsa.pub.
- They will ask you to ssh into the new bastion at `ssh 10.11.0.30`. Run ssh from .20 to connect to .30.

4. Log into the desktop gui of the GUI bastion

- Log into the .30 bastion's iDRAC at 10.6.1.52.
- In the iDRAC interface, go to Server (left navigation menu) -> Launch (right side, under Virtual Console Preview).
- The virtual console window may prompt you to allow pop-ups. Approve, close the window, and try again.
- You may see a screen that says "No Signal". If so, use the Refresh button at the top of the pop-up window.
- You will see a login screen for a RHELdesktop. Log using your .30 user password (set when your ran `passwd` on .30).

5.  Connect to the iDRAC web console for the new OpenShift nodes

Run these instructions using the gui desktop of the .30 bastion.

Open the iDRAC web console for each server you will install OpenShift on.

- Open Chrome (click the red fedora icon to the top left of the desktop and type 'Chrome', then select the option.
- WARNING: Do *NOT* use Firefox. It will complain about TLS related issues with no easy way to accept the risk and continue.
- In Chrome, use tabs to open the iDRAC web console for each server you will install OpenShift on. Just enter the IP address into the browser bar.
- When it complains about TLS, go to Advanced -> Accept.
- Enter your iDRAC username and password. The person who installed the servers for you may have helped you set this up. For a prototype environment it may be the default iDRAC username password, which are root/calvin.

The IPs for the existing iDRACs are:
  ```
  Infra:
  10.6.1.175
  10.6.1.185
  10.6.1.195

  Staging:
  10.6.1.176
  10.6.1.186
  10.6.1.196
  ```

6. Open the vitual console for each new OpenShift node

In the browser tab with the iDRAC interface for each node:

- Select "Launch" on the right side of the screen, under "Virtual Console Preview".
- The first time you do this for each node, you will be prompted about popups being blocked. Do this:
  - Click the popup icon in the top right of the window
  - Change the radio button for "Always allow popups..."
  - Select "Done"
  - Close the popup window 
  - Select  "Launch" again
- Another popup about SSL may display briefly. Wait and it will disappear.
- Another orange screen may appear briefly. Wait and it will disappear.

7. Get a shell prompt for each node

*NOTE: If you are doing a reinstall and already have CoreOS installed on the nodes, you can ssh in as the core user. `ssh -i <path to private key from install> core@<node IP>. Otherwise follow the remaining instructions in this step.

You can use the RHEL 9 boot ISO to get a shell on a machine that does not have an operating system.

From the .30 desktop, download the RHEL 9 boot ISO. At the time of writing, it has already been downloaded to `/home/install/rhel-9.8-x86_64-boot.iso`.

In the Virtual Console for each node:

- Select "Connect Virtual Media"
- Under "Map CD/DVD", select "Choose File"
- Select the RHEL 9 boot .iso file.
- Select "Map Device"
- Confirm the bar at the top of the virtual console says the device is mounted.
- From the iDRAC console for the node, power cycle the server.
- Watch the top of the screen as the machine boots. In a moment, text will appear with options to press various keys including F11. This will happen when the progress bar is about half way full.
- When the option appears, press `F11` and change the boot order to Virtual Media
- Select "One Shot..." -> "Virtual Optical Drive"
- You will see the text change to "Entering Boot Manager" with blue highlighting. Wait a minute.
- Select "One-shot UEFI Boot Menu"
- Select "Virtual Optical Drive"
- "Troubleshooting..."
- "Rescue a Red Hat Enterprise Linux..."
- Wait a few minutes
- When the menu appears, press 3 to skip to shell
- Press ENTER to continue

You should see a shell prompt.

8. Gather the storage device names for each node

From a shell on each OpenShift node, run:

```
lsblk 
```

Look at the size column. Two devices will have a size of 186.3G. Make note of their device names, which should be something like `sda` or `sdb`
We will use one device as the OpenShift boot drive, and the other will be dedicated as storage for this cluster's etcd.

Choose one device for each purpose and take note of the two device names and their purposes for each node.

9. Create custom-hosts.txt

Do this on the .20 bastion

- Create a custom-hosts.txt.

See https://access.redhat.com/support/cases/#/case/04442017 for more information.

  The custom-hosts.txt follows the following format in Plaintext
  ```
  127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
  ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

  # Rendezvous / API VIPs
  <API_VIP_IP>      api.<clustername>.<basedomain>
  <API_INT_VIP_IP>  api-int.<clustername>.<basedomain>

  # OpenShift Nodes
  <Node1_IP>        <node1_lowercase_hostname>
  <Node2_IP>        <node2_lowercase_hostname>
  <Node3_IP>        <node3_lowercase_hostname>
  ```
  Base64 Encode the File
  The MachineConfig object requires the file contents to be base64 encoded as a data URI. Run the following command in your terminal to get the encoded string:

  For example, this was the custom-hosts.txt for infra

  ```
  127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
  ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

  # Rendezvous / API VIPs
  10.11.0.24      api.infra.ocp.massopen.cloud api-int.infra.ocp.massopen.cloud
  10.11.0.25      console-openshift-console.apps.infra.ocp.massopen.cloud

  # OpenShift Nodes
  10.11.0.21      mocsec-r4pac06u33-3a
  10.11.0.22      mocsec-r4pac06u35-3a
  10.11.0.23      mocsec-r4pac06u37-3a
  ```

10. Get the base64 encoded version of custom-hosts.txt

  Bash
  ```
  cat custom-hosts.txt | base64 -w0
  ```

  You will use this in the next step as the value for `hosts_custom`.

11. ISO GENERATION

- Checkout out the https://github.com/CCI-MOC/ai-ivp/ project. 
- Update the main.yaml under <home_dir>/ai-ivp/playbooks/roles/create_agent_iso/vars to customize the agent-iso towards your cluster. 
  This is a sample main.yaml that was used for Staging
  ```
	cluster_name: staging
	base_domain: ocp.massopen.cloud
	ocp_version: "4.21"
	work_dir: "ocp_agent_install"
	ntp: 129.10.5.1
	master1_hostname: mocsec-r4pac06u33-3b
	master1_mac: a8:99:69:82:9b:dd
	master1_ip : 10.13.0.21
	master1_install_drive: /dev/sda
	master2_hostname: mocsec-r4pac06u35-3b
	master2_mac: 40:5c:fd:68:41:5d
	master2_ip : 10.13.0.22
	master2_install_drive: /dev/sdb
	master3_hostname: mocsec-r4pac06u37-3b
	master3_mac: 10:7d:1a:9c:57:5d
	master3_ip : 10.13.0.23
	master3_install_drive: /dev/sda
	rendezvous_ip: 10.13.0.21
	gateway_ip: 10.13.0.1
	dns_ip: 10.13.0.1
	cluster_network: 10.128.0.0/14
	machine_network: 10.13.0.0/16
	svc_network: 172.30.0.0/16
	api_ip: 10.13.0.24
	ingress_ip: 10.13.0.25
	hosts_custom: MTI3LjAuMC4xICAgbG9jYWxob3N0IGxvY2FsaG9zdC5sb2NhbGRvbWFpbiBsb2NhbGhvc3Q0IGxvY2FsaG9zdDQubG9jYWxkb21haW40Cjo6MSAgICAgICAgIGxvY2FsaG9zdCBsb2NhbGhvc3QubG9jYWxkb21haW4gbG9jYWxob3N0NiBsb2NhbGhvc3Q2LmxvY2FsZG9tYWluNgoKIyBSZW5kZXp2b3VzIC8gQVBJIFZJUHMKMTAuMTMuMC4yNCAgICAgIGFwaS5zdGFnaW5nLm9jcC5tYXNzb3Blbi5jbG91ZCBhcGktaW50LnN0YWdpbmcub2NwLm1hc3NvcGVuLmNsb3VkCjEwLjEzLjAuMjUgICAgICBjb25zb2xlLW9wZW5zaGlmdC1jb25zb2xlLmFwcHMuc3RhZ2luZy5vY3AubWFzc29wZW4uY2xvdWQKCiMgT3BlblNoaWZ0IE5vZGVzCjEwLjEzLjAuMjEgICAgICBtb2NzZWMtcjRwYWMwNnUzMy0zYgoxMC4xMy4wLjIyICAgICAgbW9jc2VjLXI0cGFjMDZ1MzUtM2IKMTAuMTMuMC4yMyAgICAgIG1vY3NlYy1yNHBhYzA2dTM3LTNi
	pull_secret: <pull secret to download from Redhat Repo>
	ssh_key: <use id_rsa_ocp.pub under /root/ssh on baston>
  ```
   
- Update 98-master-var-lib-etcd.j2 to make sure the correct drives are hosting etcd for each node. Edit the line that looks like this, replacing the hosts and device names to match your environment:
```
            ExecStart=/bin/bash -c 'HOST=$(hostname); if [[ "$HOST" == *"u33-3b"* ]] || [[ "$HOST" == *"u35-3b"* ]]; then TARGET="/dev/sdc"; elif [[ "$HOST" == *"u37-3b"* ]]; then TARGET="/dev/sdb"; else exit 0; fi; sgdisk -Z $TARGET && sgdisk -n 1:0:0 -c 1:etcd $TARGET && partprobe $TARGET && udevadm settle && mkfs.xfs -f /dev/disk/by-partlabel/etcd'
```
In the above example, to switch from the staging to infra environment, you would replace `u35-3b` with `u35-3a`, and `u35-3b` with `u35-3b`, etc. And for each host you replace the device name that follows it with the device name for the etcd install that you identified in an earlier step (see the PREP section).

*TODO:* use template variables for these values with Ansible and put the values in an Ansible inventory file.

- To create the ISO run 
  ```
  ansible-playbook playbooks/create_agent_iso.yaml -e "cluster_name=<cluser_name>"
  ```
- The ISO is present at <cluster_name>/agent.x86_64.iso and the kubesecret is present in <cluster_name>/auth

12. Copy the .ISO file from .20 to .30

*TODO:* remove this step when we reinstall the main bastion server to have a gui desktop (or eliminate the need to mount ISOs this way).

- On .20, run the scp command to copy the ISO to the .30 bastion. Put the file in your home directory on .30. Example: `scp -i ssh/id_rsa agent.x86_64.iso dbrletic@10.11.0.30:/home/dbrletic/agent.x86_64.iso`. 


13. Attach the ISO

- *IMPORTANT: DO NOT CLOSE THE BROWSER AT ANY POINT AFTER ATTACHING THE VIRTUAL MEDIA!!*
- Select "Connect Virtual Media"
- Under "Map CD/DVD", select "Choose File"
- Select the installation .iso file. As of the writing that file would have been you scp'd from the other bastion per the above instructions, and be located in your home directory).
- Confirm the selection

14. Reboot the server to begin the install

- Switch to the main iDRAC window and reboot the server.
- *SWITCH BACK THE VITUAL CONSOLE AND DO THIS WHEN QUICKLY THE SERVER BEGINS TO BOOT:*
  - The input from your physical keyboard to the virtual console will sometimes have latency. To overcome this, select the "Keyboard" button at the top of the virtual console menu. This will bring up a popup that looks like a keyboard. You can click the keys.
  - Watch the top of the screen as the machine boots. In a moment, text will appear with options to press various keys including F11. This will happen when the progress bar is about half way full.
  - When the option appears, press `F11` and change the boot order to Virtual Media
  - Select "One Shot..." -> "Virtual Optical Drive"

15. Monitor the install from the bastion

- SSH into the .20 bastion.

- From the staging directory that holds the recently created agent_iso you can follow the install by running
  ```
  openshift-install agent wait-for bootstrap-complete --dir <installation_directory>
  ```
  This command will block and wait until the initial control plane is up and the temporary bootstrap process has pivoted to the permanent control plane nodes. It is safe to run this immediately after booting your nodes.
  ```
  openshift-install agent wait-for install-complete --dir <installation_directory>
  ```
  Once the bootstrap is complete, run this command. It will wait until all cluster operators are available, the worker nodes have joined, and the cluster is fully operational.

16. Troubleshoot install problems

*NOTE:* The install will appear to sit idle at various points, including one point where it displays a login prompt which will go away on its own. Be patient. If it looks like it is not progressing, wait at least 30 minutes before assuming it is broken.

Once the install has progressed to the point that there is an OS running on the node and it is running an SSH daemon, you can ssh in to troubleshoot.

Use the private key that correspons to the public key that you provided when you generated the ISO.

Use the IP of the node that you provided in the installer file. Do not use the iDRAC IP.

  ```
  ssh -i /root/ssh/id_rsa_ocp core@<node IP>
  ```

### Post-Openshift Install Setup

- These steps must be performed after the OpenShift cluster install is complete, before Autoshift can be installed.
  1. Pre-configure the required secrets. 
     Since there is not a Secrets Mananger the following secrets will be needed to be created manually:
	 - Create these namespaces: "cert-mananger" and "portworx"

         - Create a github client secret
	 ```
	 oc create secret generic github-client-secret --from-literal=clientId=<YOUR_GITHUB_ID> --from-literal=clientSecret=<YOUR_GITHUB_CLIENT_SECRET> --from-literal=teamst=<YOUR_GITHUB_CLIENT_TEAMS>-n openshift-config
	 ```

         The resulting Secret object should look like this:

	 ```
	 kind: Secret
	 apiVersion: v1
	 metadata:
	   name: github-client-secret
	   namespace: openshift-config
	 stringData:
	   clientID: <Github Client ID>
	   clientSecret: <Github Client Secret>
	   teams: <Teams that are allow in >
	 type: Opaque
	  ```

         - Create a pure.json file
         ```
         {
           "FlashBlades": [
             {
               "MgmtEndPoint": "10.3.11.50",
               "APIToken": "T-ab3ca441-baf1-4742-8bb1-7c384562fd59",
               "Realm": "infra-ocp-massopen",
               "NFSEndPoint": "10.8.0.10"
             }
           ]
         }
         ``` 
	 - Create the pure.json secret from the pure.json file under the portworx namespace
	 ```
	 oc create secret generic px-pure-secret --from-file=pure.json=<file path> --namespace portworx
	 ```

	 - Create the aws-route53-credentials secret in the cert-manager namespace. 
	 ```
		kind: Secret
		apiVersion: v1
		metadata:
		  name: aws-route53-credentials
		  namespace: cert-manager
		stringData:
		  accessKeyID: <AWS ACCESS KEY>
		  commonName: <common name for the server, ie *.apps.staging.ocp.massopen.cloud>
		  dnsNames: <dns that will be controlled by the cert, ie *.apps.staging.ocp.massopen.cloud >
		  issuer-name: <A name for the issuer, ie letsencrypt-route53-staging>
		  secret-access-key: <The AWS Secret Access Key>
		type: Opaque

	 ```
	 Can also be added by command line like above. 

   2. Install the nmstate operator
      Since before Portworx can communicate with the flash blade servers we need to have some Network Setup configure first. We only need a default nmstate instance so that the CRD resource type can be created.
	  - Manually install the Nmstate Operator from the Openshift Software Catelog. You can find it on the left side of the Console under Ecosystem -> Software Catalog
	  - Search for "Nmstate" and click on "Kubernetes NMState Operator". 
	  - Choose all the default settings and install
	  - After the Nmstate operator is installed go to it, click on the NMState tab, and create a default instanace of NMState (you do not have to fill out anything). 
	  - Apply the follwing files using oc apply -f <filename> after downloading them to a local machine
           *Note:* These values work for both staging and infra because they have the same networking for portworx.
	   ```
	    kind: AdminNetworkPolicy
		metadata:
		  name: deny-pure-storage-api
		spec:
		  priority: 10
		  subject:
			namespaces:
			  matchExpressions:
				- key: kubernetes.io/metadata.name
				  operator: NotIn
				  values: [portworx]
			  egress:
			  - name: deny-pure-api
				action: Deny
				to:
				  - networks:
					- "10.3.11.50/32"
	   ```
		
	   and
	   ```
		apiVersion: nmstate.io/v1
		kind: NodeNetworkConfigurationPolicy
		metadata:
		  name: eno1-vlan-2305
		spec:
		  desiredState:
			interfaces:
			  - name: eno1.2305
				type: vlan
				state: up
				vlan:
				  base-iface: eno1
				  id: 2305
				ipv4:
				  enabled: true
				  dhcp: true
				  auto-gateway: false
				  auto-routes: false	 
	   ```
	  
	  
   3. Install portworx
     In order to install Autoshift we need the ability to create storage. Install and setting up Portworx will give our cluster access to storage on demand. 
	 - Manually install the Potworx Operator from the Openshift Software Catalog. You can find it on the left side of the Console under Ecosystem -> Software Catalog
	 - Search for "Portworx" and click on "Portworx Enterprise Operator". You can keep all the default options. 
	 - After installing go to Ecosystem -> Installed Operators -> Portworx Enterprise. Select "All Projects" on the upper Left-Center to check everwhere. 
	 - Click on the StorageCluster Tab and create a new StorageCluster
           *Note:* Thes values work for both staging and infra.
	   ```
	        kind: StorageCluster
                apiVersion: core.libopenstorage.org/v1
                metadata:
                  name: px-cluster-642c74a4-bf1c-470d-82bc-9fd32ef30015
                  namespace: portworx
                  annotations:
                    portworx.io/install-source: "https://install.portworx.com/26.1?oem=px-csi&operator=true&ce=pure&csi=true&stork=false&kbver=1.34.6&ns=portworx&osft=true&c=px-cluster-642c74a4-bf1c-470d-82bc-9fd32ef30015&tel=true"
                    portworx.io/is-openshift: "true"
                    portworx.io/misc-args: "--oem px-csi"
                spec:
                  image: portworx/px-pure-csi-driver:26.2.0
                  imagePullPolicy: Always
                  csi:
                    enabled: true
                  monitoring:
                    telemetry:
                      enabled: true
                    prometheus:
                      exportMetrics: true
				  env:
	   ```
	   
	 Watch the events to monitor the the Portworx installation. 
    - After the portworx is done installing we need to create our new storage class that uses portworx. 

      From the OpenShift Console go to:
	  Storage -> StorageClasses and click on the blue Create StorageClass button on the upper right. 
	  Apply the following file that will set Portworx as the default storage class. 
	  ```
				allowVolumeExpansion: true
                apiVersion: storage.k8s.io/v1
                kind: StorageClass
                metadata:
                  labels:
                    operator.libopenstorage.org/managed-by: portworx
                  name: pure-fb-nfsv4
                  annotations:
                    storageclass.kubernetes.io/is-default-class: 'true'
                mountOptions:
                - nfsvers=4.1
                - tcp
                parameters:
                  backend: pure_file
                  pure_nfs_policy: 'infra-policy'
                  pure_nfs_server: "infra-server"
                  # pure_nfs_export_rules_access: "no-squash" # COMMENTED SINCE LAST INSTALL. NEED TO UPDATE ON PURE SIDE.
                  pure_nfs_export_rules_client: "10.8.0.0/24"
                provisioner: pxd.portworx.com
                reclaimPolicy: Delete
                volumeBindingMode: Immediate           
	  ```
	  
7. Install Autoshift
 
   Follow the instructions and requirements to install Autoshift here:  https://github.com/auto-shift/autoshiftv2/blob/main/docs/quickstart.md
   For Step 4 this is a example of Application File to create and apply:
   ```
    apiVersion: argoproj.io/v1alpha1
	kind: Application
	  name: autoshift
	  namespace: openshift-gitops
	spec:
	  destination:
		namespace: openshift-gitops
		server: 'https://kubernetes.default.svc'
	  project: default
	  source:
		helm:
		  valueFiles:
			- values/global.yaml
			- values/clustersets/hub-minimal.yaml
			- values/clustersets/managed.yaml
		  values: |-
			autoshiftGitRepo: https://github.com/CCI-MOC/ai-ivp
			autoshiftGitBranchTag: main
		path: autoshift
		repoURL: 'https://github.com/CCI-MOC/ai-ivp.git'
		targetRevision: main
	  syncPolicy:
		automated:
		  selfHeal: true
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
 
## TROUBLESHOOTING

* If the installation hangs and the terminal for one of the nodes being installed displays:
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
