# Instructions to install an "Infra" cluster

Backgournd: This will give you some background information on what the Agent-Iso is and how it works
https://www.redhat.com/en/blog/meet-the-new-agent-based-openshift-installer-1

1. Make sure you can Login to bastion ( 10.11.0.30 ) using idrac 10.6.1.152. This is so you have access to a GUI and browser 

2. PREP
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

- Playbooks and role and everything are located on the 10.11.0.20 bastion under /home/dgroh
- If you need to change a template or variable, the role is in roles/generate_agent_files
- Update the main.yaml under /home/dgroh/roles/generate_agent_files/vars to customize the agent-iso towards your cluster. 
- To create the ISO run ansible-playbook create_agent_iso.yaml 
- If you need more granular control over the creation of the ISO (ie: support tells you to make a specific file or something) you can run generate_agent_files first to create the directory structure and the basic files, then run (from the home directory) ./openshift-install-fips agent create cluster-manifests --dir infra to generate the specific manifests, you can then add or modify a file if you need, then run ./openshift-install-fips agent create image --dir infra --log-level debug to generate the ISO manually.
- The ISO is present at infra/agent.x86_64.iso and the kubesecret is present in infra/auth

4. PUSH ISO TO NEW BASTION

- The new bastion is at 10.11.0.30, ssh 10.11.0.30 -l root, you may need to contact Naved to get access
- You can scp the file over from the old bastion, I've been using scp -i ssh/id_rsa dgroh@10.11.0.20:/home/dgroh/ingra/agent.x86_64.iso
- You'll need to create a user identity on the new bastion, an ssh key on the bastion, and add that key to your authorized_keys file in
- You might also need to copy the iso to your home folder on the old bastion and modify the scp command to pull from that
- Once the iso is on the new bastion, copy it to your home directory to simplify the next step

5. ATTACH ISO TO SERVERS AND REBOOT

- Log into the new bastion's IDRAC at 10.6.1.52 and open Virtual Console
- Log into RHEL and then open the IDRAC web console for the three servers at 10.6.1.175,185,195
- Open their web consoles an click virtual media
- DO NOT CLOSE THE BROWSER AT ANY POINT AFTER ATTACHING THE VIRTUAL MEDIA
- Attach the ISO to the servers and reboot them
- Once the install has sufficiently progressed you can ssh into them using the id_rsa_ocp key found in dgroh/.ssh on the old bastion using core@ip
