# Instructions to install using HCP

## Background
* See this link for background information on what Hosted Control Planes are and how they work
https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/hosted_control_planes/preparing-to-deploy-hosted-control-planes

## Instructions

1. Configure the Host Inventory Settings

   - From the OpenShift Console use the dropdown to switch from "Core Platform" to "Fleet Management"
   - Go to Infrastructure -> Host Inventory 
   - Click on Configure Host Inventory settings on the upper right
   - Select how much Database storage, System storage, and Image storage for the HCP

2. Configure host inventory settings

   - From the Redhat Console Switch to Fleet Management on the Upper Left.
   - Go to Infrastructure -> Host Inventory.
   - Select "Configure host inventory settings" on the upper right:
   - Fill in the vaues
     - Database storage: 10
     - System storage: 100
     - Image storage: 50
   - Select "Configure" to confirm.
  
2.1. Create an Infrastructure Environment 

   - Click on Create a Infrastructure Environment 
   - Fill out the form and add a ssh public key, pull secret, location and a name. Example values:
     - Name: staging
     - Location: east
     - Network type: DHCP only
     - CPU architecture: x86_64
     - Proxy settings: Defaults
     - Pull secret: Generate using MOC account 
     - SSH public key: generate a keypair for this cluster
     - NTP sources: Auto synchronized NTP (default)

 
3. Add Hosts to the Infrastructure Environment
   
   - Click on the Host Inventory you created
   - Click on the Hosts tab
   - On the upper right click on the Add Host button.
   - Select "With Discovery ISO". Select "Minimal image file", download, and boot to that image using iDRAC for each node you want to add to the cluser. 
   - *TODO:* Instead of "With Discovery ISO", we would prefer to use a different method that does not require an ISO. "With BMC form" would allow OpenShift to connect directly to iDRAC and install OpenShift on the node. We cannot do this with the FC430/FC830 hardware because the redfish API does not support TLS 1.3.
   - Leave "Minimal image file" selected (this is a smaller ISO upload. With this option, the node downloads the additional data from the hosting cluster.)
   - Select "Generate Discovery ISO"
   - This may take up to 2 minutes.
   - When the generation is finished, select "Download Discovery ISO".
   - The ISO will be downloaded to your local machine.
    
4. Creating a Cluster
  
   - From the Fleet Management view go to "Infrastructure" -> "Clusters"
   - Select "Create Cluster" at the top
   - Click on "Host Inventory"
   - Select "Hosted"
   - "Select a credential" -> "Add credential". Use these values:
     - Credential name: <name of your cluster>
     - Namespace: <name of your cluster> (You may have to create this namespace)
     - Base DNS domain: ocp.massopen.cloud
   - "Select a credential" again and select the one you just created.
   - Fill out the rest of the form. See hcp-resources.yaml, which was exported from the first staging install).
   - At the top of the page, select the slider for "YAML On". This will allow us to edit a setting that is not present on the form.
   - Add the yaml snippet to configure etcd to use the dedicated disk. Under HostedCluster object .spec field, add this snippet:
     ```
       etcd:
         managementType: Managed
         managed:
           storage:
             type: PersistentVolume
             persistentVolume:
               storageClassName: <name of storage class to use>
     ```
   - Select Next
   - On the Node pools page, choose the nodes from the host inventory that you want to use for this cluster.
   - Select Next
   - Fill out Networking details:
     - NotePort
     - Host port: TBD
     - Check the "Use advanced networking" checkbox
     - Cluster network CIDR: TBD
     - Cluster network host prefix: TBD
     - Service network CIDR: TBD
     - Leave "Show proxy settings" unselected
   - Select Next
   - Review the details
   - Select "Create"

   - You can click on the cluster name from the Cluster tab to monitor progress, download kubeadmin file, etc.

5.  Setting up Metallb
  
	- After the cluster is setup and installed download the kudeadmin file from the cluster panel. This will allow you to directly access the cluster without having to log in through the console
	
    
	1. Install the MetalLB Operator
	   Create a file named 1-metallb-operator.yaml with the following contents		
		```
		apiVersion: v1
		kind: Namespace
		metadata:
		  name: metallb-system
		---
		apiVersion: operators.coreos.com/v1
		kind: OperatorGroup
		metadata:
		  name: metallb-operator
		  namespace: metallb-system
		---
		apiVersion: operators.coreos.com/v1alpha1
		kind: Subscription
		metadata:
		  name: metallb-operator-sub
		  namespace: metallb-system
		spec:
		  channel: stable
		  name: metallb-operator
		  source: redhat-operators
		  sourceNamespace: openshift-marketplace
		```
		Apply it to the cluster:
		```
		oc apply -f 1-metallb-operator.yaml --kubeconfig kubeconfig.yaml
		```
	2. Initialize the MetalLB Instance
	   Wait a min or two for the operator pods to spin up
	   Create a file named 2-metallb-instance.yaml:
	   ```
		apiVersion: metallb.io/v1beta1
		kind: MetalLB
		metadata:
		  name: metallb
		  namespace: metallb-system
		```
		Apply it:
		```
		oc apply -f 2-metallb-instance.yaml --kubeconfig kubeconfig.yaml
		```
	3.	Claim the <requested> IP Address
		Once the speaker and controller pods are running in the metallb-system namespace, you need to tell MetalLB to broadcast (in this example from Staging) 10.13.0.25 onto your physical Layer 2 network so your switches know where to send the traffic.  

		Create a file named 3-metallb-pool.yaml:
		```
		apiVersion: metallb.io/v1beta1
		kind: IPAddressPool
		metadata:
		  name: ingress-public-ip
		  namespace: metallb-system
		spec:
		  addresses:
		  - 10.13.0.25-10.13.0.25
		  autoAssign: true
		---
		apiVersion: metallb.io/v1beta1
		kind: L2Advertisement
		metadata:
		  name: ingress-public-ip-adv
		  namespace: metallb-system
		spec:
		  ipAddressPools:
		  - ingress-public-ip
		```
		Apply it:
		```
		oc apply -f 3-metallb-pool.yaml --kubeconfig kubeconfig.yaml
		```
	4. 	Create a Custom Load Balancer
		Because we are running an HCP cluster, there is a "dictator" operator sitting up on your ACM Hub cluster that constantly monitors the configuration of your bare-metal cluster. If we patch  the ingresscontroller to use a LoadBalancer, the Hub operator saw the change, realized it didn't match its master blueprint, and instantly reverted the change.
		To outsmart the HCP operator, we are going to stop fighting it. We will let it keep its default ingress configuration, and instead, we will manually create our own independent LoadBalancer service.
		Because we create it manually, the Hub operator will ignore it, but MetalLB will see it, attach the 10.13.0.25(the staging example) IP, and route the traffic perfectly into the OpenShift router pods.
		
		Create a file named 4-custom-vip.yaml
		```
		apiVersion: v1
		kind: Service
		metadata:
		  name: staging-ingress-vip
		  namespace: openshift-ingress
		  annotations:
			metallb.universe.tf/address-pool: ingress-public-ip
		spec:
		  type: LoadBalancer
		  selector:
			ingresscontroller.operator.openshift.io/deployment-ingresscontroller: default
		  ports:
			- name: http
			  port: 80
			  targetPort: 80
			  protocol: TCP
			- name: https
			  port: 443
			  targetPort: 443
			  protocol: TCP
		```
		Apply it
		```
		oc apply -f 4-custom-vip.yaml --kubeconfig kubeconfig.yaml
		```
		
		You can check the status of the server by running:
		```
		oc get svc -n openshift-ingress --kubeconfig kubeconfig.yaml
		```
