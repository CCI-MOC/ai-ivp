# RHEL Headless GUI via VNC (SSH-tunneled)

These instructions are for setting up and using VNC to access the desktop GUI of a RHEL 9 server.

The VNC connections are tunneled through SSH for security.

## One-Time System Setup

Only needs to happen once ever, by whoever sets this up first. Later users skip straight to "Adding a VNC User" below.

1. ssh into the server

Replace `YOUR_USERNAME` and `SERVER_IP` below with your username and host.

```bash
ssh YOUR_USERNAME@SERVER_IP
```

2. Install a desktop environment (skip if already installed):
```bash
sudo dnf groupinstall "Server with GUI" -y
```

3. Install TigerVNC server:
```bash
sudo dnf install tigervnc-server -y
```

4. Leave the VNC ports (5900-range) **closed** on the firewall — access is only ever via SSH tunnel, never opened directly. This is because VNC's network protocol is not secure.

## Adding a VNC User

Repeat this whole section for **every** person who needs access, including the first. You need sudo for this (everyone doing this setup has it).

1. ssh into the server

2. Check which displays and ports are already in use, so you don't collide with someone else's session:
```bash
cat /etc/tigervnc/vncserver.users
sudo ss -tlnp | grep -E ':59[0-9]{2}\s'
```
The first command shows display numbers already mapped to a user; the second shows which ports are actually listening (useful in case a display was mapped but its service was never started, or vice versa). Pick the lowest display number (`:N`) that appears in **neither** list. Its port is `5900+N` -- e.g. `:2` is port `5902`.

3. Map that display number to your username (replace `N` and `YOUR_USERNAME`):
```bash
sudo tee -a /etc/tigervnc/vncserver.users << 'EOF'
:N=YOUR_USERNAME
EOF
```

4. Enable and start your own service instance:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vncserver@:N.service
sudo systemctl status vncserver@:N.service
```

5. Set your own VNC password (separate from your system login password, and separate from everyone else's):
```bash
vncpasswd
```
You do not need to set a 'read-only password'.

6. Create your server config to use that password and launch GNOME:
```bash
mkdir -p ~/.config/tigervnc
cat > ~/.config/tigervnc/config << 'EOF'
securitytypes=vncauth
session=gnome
EOF
```

7. Restart *your own* service instance to pick up the config — use your own `:N`, not anyone else's, so you don't disrupt another user's running session:
```bash
sudo systemctl restart vncserver@:N.service
```

8. Confirm it's listening on your port:
```bash
sudo ss -tlnp | grep 590N
```

9. Back on your local machine, install a VNC viewer if you do not have one:

For example, in Fedora:
```bash
sudo dnf install tigervnc -y
```

## Connecting to the server via VNC

Do this every time you want to connect. Always use the port for **your own** display from the "Adding a VNC User" section above — never someone else's.

1. Open an SSH tunnel (leave this terminal open):

Replace `YOUR_USERNAME`, `SERVER_IP`, and `590N` (your own port) below.

```bash
ssh -L 590N:localhost:590N YOUR_USERNAME@SERVER_IP
```

2. Connect your VNC viewer to the server:

Instructions will vary based on what VNC viewer software you are using.

Example using tigervnc:
```bash
vncviewer localhost:590N
```

3. Enter the password you set with `vncpasswd`. You should land on your own GNOME desktop.

## Informational: Why each user gets their own VNC display, not a shared password

VNC has no concept of separate logins the way SSH does -- a VNC password just gates access to one specific, already-running desktop session. If two people share one password, they're both controlling the *exact same* session simultaneously (one mouse, one keyboard, whoever typed last wins), and there's no way to tell who did what.

That matters more than usual on the bastion specifically: it's used to keep browser tabs open for hours during OpenShift installs (see [README_INSTALL_HUB.md](README_INSTALL_HUB.md)), where closing the wrong tab breaks someone else's in-progress install. Sharing a session means either person could accidentally close or navigate away from a tab the other is depending on.

We also don't want to share a vnc password.

So: each user gets their own VNC display (`:1`, `:2`, `:3`, ...), each with its own password and its own independent GNOME session. Nobody shares credentials.


