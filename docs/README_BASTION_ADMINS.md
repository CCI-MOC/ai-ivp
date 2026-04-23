# Setting up Admin Users for the Bastion Server

When the hardware is provisioned, log in to the server via SSH as the `root` account. Follow these instructions to set up individual administrative users directly on the box.

## Prerequisites:

* The IP of the bastion server.
* Root access to the bastion server (your SSH key must be in the root authorized_keys).

## Instructions:

0. SSH into the bastion server as root
```bash
ssh root@<Bastion Server IP>
```

1. Install Dependencies
Install Git, Ansible, and the required Ansible collections the bastion server:
```bash
dnf install -y git ansible-core
```

2. Clone this repository locally
```bash
git clone https://github.com/CCI-MOC/ai-ivp.git
cd ai-ivp/
```

3. Configure the Secret (One-time setup)
We use Ansible Vault to encrypt the temporary password. You will be prompted to create a Vault Password-keep this safe, as you will need it to run the playbook.

```bash
ansible-vault create vars/secrets.yaml
```

Inside the editor that opens, paste:

```yaml
temp_sudo_password: "Choose_A_Strong_Temp_Password"
```

4. Add Public Keys
For each admin user, create a file in the admin_public_keys/ directory. The filename must match the intended username.

```bash
mkdir -p admin_public_keys/
# Example for user 'jsmith'
vi admin_public_keys/jsmith.pub
# Paste their public key, save and exit (:wq)
```

5. Run the Playbook
Run the playbook for each user.

```bash
ansible-playbook playbooks/add-bastion-admin.yaml -e "username=<Target_Username>" --ask-vault-pass
```

6. Confirm Access

The new user should now be able to log in and will be prompted to change their password on their first sudo command:

```bash
ssh <username>@<BASTION_IP>
```

7. Have the user change their password

Using their initial password, have the new admin set a new password. Do not prefix this command with `sudo`:

```bash
passwd
```

8. Have the user test sudo access

This command should ask for their (new) password and then display their username:

```bash
sudo whoami
```

