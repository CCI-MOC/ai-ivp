# RHEL Headless GUI via VNC (SSH-tunneled)

Sets up a GUI desktop on a headless RHEL box, accessible remotely over VNC
tunneled through SSH. Uses VNC's own password (`vncpasswd`), not system PAM auth.

Replace `YOUR_USERNAME` and `SERVER_IP` below with your username and host.

## 1. Set up VNC on the RHEL server

Install a desktop environment (skip if already installed):
```bash
sudo dnf groupinstall "Server with GUI" -y
```

Install TigerVNC server:
```bash
sudo dnf install tigervnc-server -y
```

Map display `:1` to your user:
```bash
sudo tee -a /etc/tigervnc/vncserver.users << 'EOF'
:1=YOUR_USERNAME
EOF
```

Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vncserver@:1.service
sudo systemctl status vncserver@:1.service
```

Leave port 5901 **closed** on the firewall — access is only via SSH tunnel, never opened directly.

## 2. Set up config for the user

Set a VNC password (separate from your system login password):
```bash
vncpasswd
```

Create the server config to use that password and launch GNOME:
```bash
mkdir -p ~/.config/tigervnc
cat > ~/.config/tigervnc/config << 'EOF'
securitytypes=vncauth
session=gnome
EOF
```

Restart the service to pick up the config:
```bash
sudo systemctl restart vncserver@:1.service
```

Confirm it's listening:
```bash
sudo ss -tlnp | grep 5901
```

## 3. Connect from your client machine

Open an SSH tunnel (leave this terminal open):
```bash
ssh -L 5901:localhost:5901 YOUR_USERNAME@SERVER_IP
```

Install a VNC viewer if needed (Fedora example):
```bash
sudo dnf install tigervnc -y
```

Connect:
```bash
vncviewer localhost:5901
```

Enter the password you set with `vncpasswd` — you should land on a GNOME desktop.
