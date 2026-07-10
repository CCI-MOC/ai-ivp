# Instructions to install an "Infra" cluster

Backgournd: This will give you some background information on what the Agent-Iso is and how it works
https://www.redhat.com/en/blog/meet-the-new-agent-based-openshift-installer-1

1. Make sure you can Login to bastion ( 10.11.0.30 ) using idrac 10.6.1.152. This is so you have access to a GUI and browser. Also make sure to 

2. PREP
- Make sure butane and openshift-install-fips are in the /usr/local/bin directory for the whole server to user.
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
4. ISO GENERATION

- Checkout out the https://github.com/CCI-MOC/ai-ivp/ project. 
- Update the main.yaml under <home_dir>/ai-ivp/playbooks/vars to customize the agent-iso towards your cluster. 
- To create the ISO run 
  ```
  ansible-playbook create_agent_iso.yaml -e "cluster_name=<cluser_name>"
  ```
- The ISO is present at <cluster_name>/agent.x86_64.iso and the kubesecret is present in <cluster_name>/auth

4. PUSH ISO TO NEW BASTION

- The new bastion is at 10.11.0.30, ssh 10.11.0.30 -l root, you may need to contact Naved to get access
- You can scp the file over from the old bastion, I've been using scp -i ssh/id_rsa dgroh@10.11.0.20:/home/dgroh/ingra/agent.x86_64.iso
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

- For troubleshooting once the install has sufficiently progressed you can ssh into them using the id_rsa_ocp key found in dgroh/.ssh on the old bastion using core@ip, ie  
  ```
  ssh -i /root/ssh/id_rsa_ocp core@10.13.0.22
  ```
