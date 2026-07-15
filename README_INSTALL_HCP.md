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
   - Fill out the rest of the form. Use the following YAML for reference, pulling out the values on the form.
		```	 
		apiVersion: hypershift.openshift.io/v1beta1
		kind: HostedCluster
		metadata:
		  name: staging
		  namespace: staging
		  labels:
			cluster.open-cluster-management.io/clusterset: managed
		spec:
		  etcd:
			managementType: Managed
			managed:
			  storage:
				type: PersistentVolume
				persistentVolume:
				  storageClassName: local-storageclass
		  channel: fast-4.21
		  release:
			image: quay.io/openshift-release-dev/ocp-release:4.21.22-multi
		  pullSecret:
			name: pullsecret-cluster-staging
		  sshKey:
			name: sshkey-cluster-staging
		  networking:
			clusterNetwork:
			  - cidr: 10.132.0.0/14
				hostPrefix: 23
			serviceNetwork:
			  - cidr: 172.31.0.0/16
			networkType: OVNKubernetes
		  controllerAvailabilityPolicy: HighlyAvailable
		  infrastructureAvailabilityPolicy: HighlyAvailable
		  olmCatalogPlacement: management
		  platform:
			type: Agent
			agent:
			  agentNamespace: staging-test
		  infraID: staging
		  dns:
			baseDomain: ocp.massopen.cloud
		  services:
			- service: APIServer
			  servicePublishingStrategy:
				type: NodePort
				nodePort:
				  address: 10.11.0.21
				  port: 30443
			- service: OAuthServer
			  servicePublishingStrategy:
				type: Route
			- service: OIDC
			  servicePublishingStrategy:
				type: Route
			- service: Konnectivity
			  servicePublishingStrategy:
				type: Route
			- service: Ignition
			  servicePublishingStrategy:
				type: Route
		---
		apiVersion: v1
		kind: Secret
		metadata:
		  name: pullsecret-cluster-staging
		  namespace: staging
		data:
		  .dockerconfigjson: >-
			eyJhdXRocyI6eyJjbG91ZC5vcGVuc2hpZnQuY29tIjp7ImF1dGgiOiJiM0JsYm5Ob2FXWjBMWEpsYkdWaGMyVXRaR1YySzJSaWNteGxkR2xqY21Wa2FHRjBZMjl0TVd4eWRqbGhObXQxWVc1MlozY3hlWGQwWjNGek9YWnZkbVZ0T2paWVVrWlNRbHBOVFVKWlJFVkxSVU0xUnpOT1UxZEZRbGRVUWpKTFZrdFJOMDVNUlZGTlQwVTVSVkZTUkVGRlJrWlFNRTlLUVZnMFVGcE5WMWMzVDAwPSIsImVtYWlsIjoiZGJybGV0aWNAcmVkaGF0LmNvbSJ9LCJxdWF5LmlvIjp7ImF1dGgiOiJiM0JsYm5Ob2FXWjBMWEpsYkdWaGMyVXRaR1YySzJSaWNteGxkR2xqY21Wa2FHRjBZMjl0TVd4eWRqbGhObXQxWVc1MlozY3hlWGQwWjNGek9YWnZkbVZ0T2paWVVrWlNRbHBOVFVKWlJFVkxSVU0xUnpOT1UxZEZRbGRVUWpKTFZrdFJOMDVNUlZGTlQwVTVSVkZTUkVGRlJrWlFNRTlLUVZnMFVGcE5WMWMzVDAwPSIsImVtYWlsIjoiZGJybGV0aWNAcmVkaGF0LmNvbSJ9LCJyZWdpc3RyeS5jb25uZWN0LnJlZGhhdC5jb20iOnsiYXV0aCI6Ik5qQTVOREkyT0h4MWFHTXRNVXh5VmpsaE5rdDFRVzUyUjNjeFdYZDBaMUZ6T1haUGRrVnRPbVY1U21oaVIyTnBUMmxLVTFWNlZYaE5hVW81TG1WNVNucGtWMGxwVDJsSmVGcFhTWHBaYW14cldsZEdiRTlFUVRCT1YwcHJXVlJaTUU1VVJYZFBWMFpxV1hwR2FVMUhWVEZaVTBvNUxrUndWRXhIY25WQlFVTnlkRlJSUTAxUFIwYzRVblZET1RjelRsaDViMXBYWkdsdFdtVkJibmhIVDBoWGIyaExhRFJmTkV0b1NGWmhRa3RwTFdndFlXZHZRWGRoZURoSVZIY3dhRUpSTFZsYU1qZHNTRlZzVm5WT2NVeEdOMnhvWDJ4NFREaEZaRlZqWW5kclQwb3dNRmxpUlZweWFFVk5WRFl0WkhKTlJrbFNMVkZoYVY4ek5XeFRSMlZ2VXpkM1FUUjJiakkzY0VsRlRsTm5VbU5pYjFkNFJHNUdaVEp1ZUMweWNqRk1ORzUyZGxwSGNFZEpjV3h1ZDA5SU5FNVVTV2d5VFdwS1ZWOUhabU5JU3kxTk1FeDZTSEl5WDAxYVIzQjROMk5XTFcxbVowdzBSa3R3Ymtob2JEaFJSV1JNUm5OeWFHdHpOWE5IZG0xYWIwcE9WbXR1UmxCWlRsSktSMEZYTUU1TGNrSmhiWGx2UVU4MFEweGZjblIwTjJ3eFdXOUhaM0p1TkRoTmRWVlNOQzFFUTFSc1dGRlNVVnBLTjJaYVdtNXJRVTgyTWtsTVdsZEhWMDB5Tmw5TlVteDRZekV6TjJ0dmVFdzRSM1Z4VTJkRldqVm9Va2w1VG5wRVRYcHZNVmRrYWprM2RWWjRaMjVTUlUxMmRGWkhSRE5XUmxJNVlVZzFNSEU0ZVMxblkxcDNWVk5PUmw5MlZqRTFYMUpSYjI0eVkxVklSSFkxV0hkMlJUVTNSbkZ5VHpZNGRrdElTM3BTU1hOcVRVWkRNVmhXVG5GTFNqZFhTRUZ0Wm0xQ04yOHpSVko1UVhsRFFVczBkMUoyZEdOdVpHbzVUVU5VVFhCRGNGWXhkbll4UWtkcU4xWkNkaTE1T1ROUVdrMXhSREpKVm04NVFrWk5Ra2wwWWtaUE1YVk5TbTFDZURkTFJXaE5kWGxsVXpaM1JsWnBkSGN4U2pGRlUyeDZWR28zWjBOVFVXcHdUMjVZYldKek5XOWZURU5zYkY4eGRFbEdhRFYzUlUxU1JFTjJOMGxZWHpaVVYyZG9kRkZ0VW5WS2FURkxlVEZwU2xab01VeDBUMmh4VUZkRFRWbElTV1JpWmtsSVdFeEtja05MUjBjMFJIQnROV0ZHYTAxTGNHTk5hSE52TkRWWlEwdEJOamg2VlhsUU9HTllaWGt5VmpsamQzVnBOa0ZzYTNCTiIsImVtYWlsIjoiZGJybGV0aWNAcmVkaGF0LmNvbSJ9LCJyZWdpc3RyeS5yZWRoYXQuaW8iOnsiYXV0aCI6Ik5qQTVOREkyT0h4MWFHTXRNVXh5VmpsaE5rdDFRVzUyUjNjeFdYZDBaMUZ6T1haUGRrVnRPbVY1U21oaVIyTnBUMmxLVTFWNlZYaE5hVW81TG1WNVNucGtWMGxwVDJsSmVGcFhTWHBaYW14cldsZEdiRTlFUVRCT1YwcHJXVlJaTUU1VVJYZFBWMFpxV1hwR2FVMUhWVEZaVTBvNUxrUndWRXhIY25WQlFVTnlkRlJSUTAxUFIwYzRVblZET1RjelRsaDViMXBYWkdsdFdtVkJibmhIVDBoWGIyaExhRFJmTkV0b1NGWmhRa3RwTFdndFlXZHZRWGRoZURoSVZIY3dhRUpSTFZsYU1qZHNTRlZzVm5WT2NVeEdOMnhvWDJ4NFREaEZaRlZqWW5kclQwb3dNRmxpUlZweWFFVk5WRFl0WkhKTlJrbFNMVkZoYVY4ek5XeFRSMlZ2VXpkM1FUUjJiakkzY0VsRlRsTm5VbU5pYjFkNFJHNUdaVEp1ZUMweWNqRk1ORzUyZGxwSGNFZEpjV3h1ZDA5SU5FNVVTV2d5VFdwS1ZWOUhabU5JU3kxTk1FeDZTSEl5WDAxYVIzQjROMk5XTFcxbVowdzBSa3R3Ymtob2JEaFJSV1JNUm5OeWFHdHpOWE5IZG0xYWIwcE9WbXR1UmxCWlRsSktSMEZYTUU1TGNrSmhiWGx2UVU4MFEweGZjblIwTjJ3eFdXOUhaM0p1TkRoTmRWVlNOQzFFUTFSc1dGRlNVVnBLTjJaYVdtNXJRVTgyTWtsTVdsZEhWMDB5Tmw5TlVteDRZekV6TjJ0dmVFdzRSM1Z4VTJkRldqVm9Va2w1VG5wRVRYcHZNVmRrYWprM2RWWjRaMjVTUlUxMmRGWkhSRE5XUmxJNVlVZzFNSEU0ZVMxblkxcDNWVk5PUmw5MlZqRTFYMUpSYjI0eVkxVklSSFkxV0hkMlJUVTNSbkZ5VHpZNGRrdElTM3BTU1hOcVRVWkRNVmhXVG5GTFNqZFhTRUZ0Wm0xQ04yOHpSVko1UVhsRFFVczBkMUoyZEdOdVpHbzVUVU5VVFhCRGNGWXhkbll4UWtkcU4xWkNkaTE1T1ROUVdrMXhSREpKVm04NVFrWk5Ra2wwWWtaUE1YVk5TbTFDZURkTFJXaE5kWGxsVXpaM1JsWnBkSGN4U2pGRlUyeDZWR28zWjBOVFVXcHdUMjVZYldKek5XOWZURU5zYkY4eGRFbEdhRFYzUlUxU1JFTjJOMGxZWHpaVVYyZG9kRkZ0VW5WS2FURkxlVEZwU2xab01VeDBUMmh4VUZkRFRWbElTV1JpWmtsSVdFeEtja05MUjBjMFJIQnROV0ZHYTAxTGNHTk5hSE52TkRWWlEwdEJOamg2VlhsUU9HTllaWGt5VmpsamQzVnBOa0ZzYTNCTiIsImVtYWlsIjoiZGJybGV0aWNAcmVkaGF0LmNvbSJ9fX0K
		type: kubernetes.io/dockerconfigjson
		---
		apiVersion: v1
		kind: Secret
		metadata:
		  name: sshkey-cluster-staging
		  namespace: staging
		stringData:
		  id_rsa.pub: <public ssh key>
		---
		apiVersion: hypershift.openshift.io/v1beta1
		kind: NodePool
		metadata:
		  name: nodepool-staging-1
		  namespace: staging
		spec:
		  clusterName: staging
		  replicas: 3
		  management:
			autoRepair: false
			upgradeType: InPlace
		  platform:
			type: Agent
			agent:
			  agentLabelSelector:
				matchLabels: {}
		  release:
			image: quay.io/openshift-release-dev/ocp-release:4.21.22-multi
		---
		apiVersion: cluster.open-cluster-management.io/v1
		kind: ManagedCluster
		metadata:
		  name: staging
		  annotations:
			import.open-cluster-management.io/hosting-cluster-name: local-cluster
			import.open-cluster-management.io/klusterlet-deploy-mode: Hosted
			open-cluster-management/created-via: hypershift
		  labels:
			name: staging
			cloud: BareMetal
			vendor: OpenShift
			cluster.open-cluster-management.io/clusterset: managed
		spec:
		  hubAcceptsClient: true
		---
		apiVersion: agent.open-cluster-management.io/v1
		kind: KlusterletAddonConfig
		metadata:
		  name: staging
		  namespace: staging
		spec:
		  clusterName: staging
		  clusterNamespace: staging
		  clusterLabels:
			cloud: BareMetal
			vendor: OpenShift
		  applicationManager:
			enabled: true
		  policyController:
			enabled: true
		  searchCollector:
			enabled: true
		  certPolicyController:
			enabled: true
		```	 
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
