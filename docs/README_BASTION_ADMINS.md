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
dnf install -y git ansible-core
```

2. Clone this repository locally (One time setup per user that creates accounts)
```bash
git clone https://github.com/CCI-MOC/ai-ivp.git
cd ai-ivp/
```

3. Configure the Temporary Password
We use Ansible Vault to encrypt the temporary password. You will be prompted to create a Vault Password-keep this safe, as you will need it to run the playbook.

The first time you do this:

```bash
ansible-vault create playbooks/vars/secrets.yaml
```

Ansible will ask you for a vault password. Set this to something secure and remember it because you will need to use it to run the playbook.

For subsequent users, the vault is already created, so you will use the `edit` subcommand instead of `create`.
```bash
ansible-vault edit playbooks/vars/secrets.yaml
```

Inside the vault editor that opens, paste:

```yaml
temp_sudo_password: "Choose_A_Strong_Temp_Password"
```

If there is a value present, change it to assign a different temporary password to the new user.

4. Add Public Keys
 
Create a file in the playbooks/admin_public_keys/ directory. The filename must match the requested username. Paste the new user's public key into the file. You can get the requested username and public key from the access request ticket.

```bash
mkdir -p playbooks/admin_public_keys/
# Example for user 'jsmith'
vi playbooks/admin_public_keys/jsmith.pub
# Paste their public key, save and exit (:wq)
```

5. Run the Playbook
Run the playbook for each user.

```bash
ansible-playbook playbooks/add-bastion-admin.yaml -e "username=<Target_Username>" --ask-vault-pass
```

6. Contact the new user

You can get the user's preferred contact information from the access request ticket. Let the new know that their account has been created, how to connect, their temporary sudo password, and the next steps that they should take (i.e. testing the connection and changing their temporary password). The remaining steps document what they should do.

**Note:** At this time, Slack and Email are not approved mediums to transmit temporary passwords for this environment. Giving them the password over the phone is allowed.

6. Confirm Access

The new user should now be able to log in to the bastion:

```bash
ssh <username>@<BASTION_IP>
```

**NOTE:** They must login using the private key that corresponds to the public key they provided in the ticket. Password based ssh login is disabled.

7. Have the user change their password

Using their initial password, have the new admin set a new password. Do **not** prefix this command with `sudo`:

```bash
passwd
```

8. Have the user test sudo access

This command should ask for their (new) password and then display their username:

```bash
sudo whoami
```

# Troubleshooting
# If the user cannot ssh into the bastion
* They must be on the VPN.
* Only certain cyphers are supported for the keypair used to login. id-rsa works. ssh-ed25519 does not.
