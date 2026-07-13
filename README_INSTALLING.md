# Instructions to install an "Infra" cluster

## Background
* See this link for background information on what the Agent-Iso is and how it works
https://www.redhat.com/en/blog/meet-the-new-agent-based-openshift-installer-1

## Instructions

1. Make sure you can Login to bastion ( 10.11.0.30 ) using idrac 10.6.1.152. This is so you have access to a GUI and browser. Also make sure you have the ability to scp beteen .20 and .30

2. PREP
- Make sure butane and openshift-install-fips are in the /usr/local/bin directory.
- Create a custom-hosts.txt. (See https://access.redhat.com/support/cases/#/case/04442017 for more information).
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

  Bash
  ```
  cat custom-hosts.txt | base64 -w0
  ```

  Update the main.yml hosts_custom with this base64 string.
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
- Log into each node and run 
  ```
  lsblk 
  ```
  And take note of the drives. Pick one that will be the OpenShift install and pick one that will be the install drive for etcd. 
4. ISO GENERATION

- Checkout out the https://github.com/CCI-MOC/ai-ivp/ project. 
- Update the main.yaml under <home_dir>/ai-ivp/playbooks/vars to customize the agent-iso towards your cluster. 
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
   
- Update 98-master-var-lib-etcd.j2 to make sure the correct drives are hosting etcd for each node
- To create the ISO run 
  ```
  ansible-playbook create_agent_iso.yaml -e "cluster_name=<cluser_name>"
  ```
- The ISO is present at <cluster_name>/agent.x86_64.iso and the kubesecret is present in <cluster_name>/auth

4. PUSH ISO TO NEW BASTION

- The new bastion is at 10.11.0.30, ssh 10.11.0.30 -l root, you may need to contact Naved to get access
- You can scp the file over from the old bastion, I've been using scp -i ssh/id_rsa dbrletic@10.11.0.20:/home/dbrletic/agent.x86_64.iso
- You'll need to create a user identity on the new bastion, an ssh key on the bastion, and add that key to your authorized_keys file in
- You might also need to copy the iso to your home folder on the old bastion and modify the scp command to pull from that
- Once the iso is on the new bastion, copy it to your home directory to simplify the next step

5. ATTACH ISO TO SERVERS AND REBOOT

- Log into the new bastion's IDRAC at 10.6.1.52 and open Virtual Console
- Log into RHEL and then open the IDRAC web console for the three servers at 
  ```
  Infra
  10.6.1.175,185,195
  Staging
  10.6.1.176,186,196
  ```
- Open their web consoles an click virtual media
- DO NOT CLOSE THE BROWSER AT ANY POINT AFTER ATTACHING THE VIRTUAL MEDIA
- Attach the ISO to the servers and reboot them
- Press F11 and change the boot order to Virtual Media
- From the staging directory that holds the recently created agent_iso you can follow the install by running
  ```
  openshift-install agent wait-for bootstrap-complete --dir <installation_directory>
  ```
  This command will block and wait until the initial control plane is up and the temporary bootstrap process has pivoted to the permanent control plane nodes. It is safe to run this immediately after booting your nodes.
  ```
  openshift-install agent wait-for install-complete --dir <installation_directory>
  ```
  Once the bootstrap is complete, run this command. It will wait until all cluster operators are available, the worker nodes have joined, and the cluster is fully operational.

- For troubleshooting once the install has sufficiently progressed you can ssh into them using the id_rsa_ocp key found in /root/ssh on the old bastion using core@ip, ie  
  ```
  ssh -i /root/ssh/id_rsa_ocp core@10.13.0.22
  ```

6. Post-Openshift Install Setup


- These steps must be performed after the OpenShift cluster install is complete, before Autoshift can be installed.
  1. Pre-configure the required secrets. 
     Since there is not a Secrets Mananger the following secrets will be needed to be created manually:
	 - Create the namespace "cert-mananger" and "portworx"
	 - Fill out and apply the following Secret under the "openshift-config" namespace:
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
     This can be done by either creating the file manually in OpenShift or by running the command line
	 ```
	 oc create secret generic github-client-secret --from-literal=clientId=<YOUR_GITHUB_ID> --from-literal=clientSecret=<YOUR_GITHUB_CLIENT_SECRET> --from-literal=teamst=<YOUR_GITHUB_CLIENT_TEAMS>-n openshift-config
	 ```
	 - Creating the pure.json secret from the pure.json file under the portworx namespace
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
	 - Manually install the Potworx Operator from the Openshift Software Catelog. You can find it on the left side of the Console under Ecosystem -> Software Catalog
	 - Search for "Portworx" and click on "Portworx Enterprise Operator". You can keep all the default options. 
	 - After installing go to Ecosystem -> Installed Operators -> Portworx Enterprise. Select "All Projects" on the upper Left-Center to check everwhere. 
	 - Click on the StorageCluster Tab and create a new StorageCluster
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
	   
	  Since we have already setup our pure.json all we have to do now is watch the events to monitor the the Portworx installation. 
    - After the portworx is done installing we need to create our new storage class that used portworx. 
      From the OpenShift Console go to
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
                  pure_nfs_export_rules_access: "no-squash"
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
	The Route for ArgoCD can be found under Network -> Routes in the openshift-gitops namespace. 
	To find the admin password for ArgoCD go to Workload -> Secrets and check in the infra-gitops-cluster secret in the openshift-gitops namespace. 
