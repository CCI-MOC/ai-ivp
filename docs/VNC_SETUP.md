# RHEL Headless GUI via VNC (SSH-tunneled)

These instructions are for setting up and using VNC to access the desktop GUI of a RHEL 9 server.

The VNC connections are tunneled through SSH for security.

## One-Time VNC Server Installation on the Server

1. ssh into the server

Replace `YOUR_USERNAME` and `SERVER_IP` below with your username and host.

```
ssh YOUR_USERNAME@SERVER_IP
```

3. Install a desktop environment (skip if already installed):
```bash
sudo dnf groupinstall "Server with GUI" -y
```

3. Install TigerVNC server:
```bash
sudo dnf install tigervnc-server -y
```

4. Map display `:1` to your user:

Replace `YOUR_USERNAME` below with your username.

```bash
sudo tee -a /etc/tigervnc/vncserver.users << 'EOF'
:1=YOUR_USERNAME
EOF
```

5. Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vncserver@:1.service
sudo systemctl status vncserver@:1.service
```

6. Leave port 5901 **closed** on the firewall — access is only via SSH tunnel, never opened directly. This is because VNC's network protocol is not secure.

## 2. Per-User VNC Configuration on the Server

Each user that needs VNC access must do these steps.

1. ssh into the server

2. Set a VNC password (separate from your system login password):
```bash
vncpasswd
```

You do not need to set a 'read-only password'.

3. Create the server config to use that password and launch GNOME:

```bash
mkdir -p ~/.config/tigervnc
cat > ~/.config/tigervnc/config << 'EOF'
securitytypes=vncauth
session=gnome
EOF
```

4. Restart the service to pick up the config:
```bash
sudo systemctl restart vncserver@:1.service
```

5. Confirm it's listening:
```bash
sudo ss -tlnp | grep 5901
```

6. Back on your local machine, install a VNC viewer if you do not have one

For example, in Fedora:
```bash
sudo dnf install tigervnc -y
```

## Connecting to the server via VNC

Do this every time you want to connect to the bastion over VNC

1. Open an SSH tunnel (leave this terminal open):

Replace `YOUR_USERNAME` and `SERVER_IP` below with your username and host.

```bash
ssh -L 5901:localhost:5901 YOUR_USERNAME@SERVER_IP
```

2. Connect your VNC viewer to the server:

Instructions will vary based on what VNC viewer software you are using.

Example using tigervnc:
```bash
vncviewer localhost:5901
```

3. Enter the password you set with `vncpasswd`. you should land on a GNOME desktop.
