# Adding Admin Users to the Bastion Server

The bastion server is used to install the Infra cluster, and then manage the environment using cli tools. It is accessed using a local account that must be created the bastion server. We have to run through these instructions every time a user must be added. This includes the intial users created after the hardware is provisioned.

## Prerequisites:

* A **documented and approved** request to create the new user. These are tracked as GitHub issues in the [access-requests repository](https://github.com/CCI-MOC/access-requests/issues). If you are someone who does this routinely, you should watch that repository.
* The contact info, username, and public key for the new user. These should be in the ticket.
* The IP of the bastion server.
* The ability to login to the bastion server, OR the ability to login as the root user which should only be done for the first person-specific user account.
* Sudo access to run the automation that creates the new user.
  
## Instructions:

0. SSH into the bastion server. The user will be the one that was created for you. When the bastion hardware is first provisioned, the root user will have to be used one time to create the first person-specific user.
```bash
ssh myuser@<Bastion Server IP>
```

1. Install Dependencies (One time setup per bastion server)
Install Git, Ansible, and the required Ansible collections the bastion server:
```bash
sudo dnf install -y git ansible-core
sudo ansible-galaxy install -r playtbooks/requirements.yaml
```

2. Clone this repository locally (One time setup per user that creates accounts)
```bash
git clone https://github.com/CCI-MOC/ai-ivp.git
cd ai-ivp/
```

3. Add Users and Public Keys
 
Create a file `playbooks/group_vars/all/bastion_users.yaml`. For each user, and an entry to the `bastion_users` key that contains their username, full name, and ssh key:

```bash
cat > playbooks/group_vars/all/bastion_users.yaml <<EOF
bastion_users:
- username: alice
  fullname: Alice User
  ssh_key: "ssh-rsa ..."
- username: bob
  fullname: Bob Person
  ssh_key: "ssh-rsa ..."
EOF
```

5. Run the Playbook

This will create user accounts for all the listed users.

```bash
sudo ansible-playbook playbooks/add-bastion-admin.yaml
```

6. Contact the new user

You can get the user's preferred contact information from the access request ticket. Let the new know that their account has been created, how to connect, and the next steps that they should take (i.e. testing the connection and setting their password). The remaining steps document what they should do.

6. Confirm Access

The new user should now be able to log in to the bastion:

```bash
ssh <username>@<BASTION_IP>
```

**NOTE:** They must login using the private key that corresponds to the public key they provided in the ticket. Password based ssh login is disabled.

7. Have the user change their password

The user will be prompted to set a password when they first log in. Once the password is set, they will be disconnected and will need to re-connect.

```
WARNING: Your password has expired.
You must change your password now and login again!
Changing password for user lars.
New password:

```

8. Have the user test sudo access

Have the user log back in and run a command with `sudo`. This command should ask for their (new) password and then display their username:

```bash
sudo whoami
```

# Troubleshooting
# If the user cannot ssh into the bastion
* They must be on the VPN.
* Only certain cyphers are supported for the keypair used to login. id-rsa works. ssh-ed25519 does not.
