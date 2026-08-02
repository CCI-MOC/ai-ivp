# Booting from a RHEL ISO to investigate an OpenShift node

Sometimes you want to run shell commands on a node, but it doesn't have an operating system yet. For example, you might want to get information about the installed hardware like storage device serial numbers or MAC addresses.

You can boot from a RHEL boot ISO to run exploratory commands.

# Notes

* The optional first step explains how to hop from your local desktop to the bastion server's virtual console, which you can then use a browser in to open the virtual console of the target node. *This is inconvenient but can be used for fast ISO uploads.* If you don't want to do that, just skip step #1. You could also set up VNC or RDP into the bastion.
* You can also use these steps to boot from vanilla a CoreOS ISO or any other ISO.

# Prerequisites

1. You need the iDRAC IPs of the node you want to boot RHEL from. If you use the optional first step, you also need the iDRAC IP of the bastion. See [Environment Details](/docs/ENVIRONMENT.md)

# Instructions

1. Optional: Log into the desktop gui of the bastion server

*NOTE: Skip this step if you just want to login to the node straight from your local desktop. The ISO upload will take longer. To do this, the bastion must have a gui desktop installed and running.

You can use the iDRAC virtual console for this.

- Using a browser on your desktop, iog into the 30 bastion's iDRAC
- In the iDRAC interface, go to Server (left navigation menu) -> Launch (right side, under Virtual Console Preview).
- The virtual console window may prompt you to allow pop-ups. Approve, close the window, and try again.
- You may see a screen that says "No Signal". If so, use the Refresh button at the top of the pop-up window.
- You will see a login screen for a RHELdesktop. Log using your .30 user password (set when your ran `passwd` on .30).

2.  Connect to the iDRAC web console for the new OpenShift nodes

You these instructions using the gui desktop of the bastion.

Open the iDRAC web console for each server you will install OpenShift on.

- Open Chrome (click the red fedora icon to the top left of the desktop and type 'Chrome', then select the option.
- WARNING: Do *NOT* use Firefox. It will complain about TLS related issues with no easy way to accept the risk and continue.
- In Chrome, use tabs to open the iDRAC web console for each server you will install OpenShift on. Just enter the IP address into the browser bar.
- When it complains about TLS, go to Advanced -> Accept.
- Enter your iDRAC username and password. The person who installed the servers for you may have helped you set this up. For a prototype environment it may be the default iDRAC username password, which are root/calvin.

3. Open the vitual console in iDRAC

- Select "Launch" on the right side of the screen, under "Virtual Console Preview".
- The first time you do this for each node, you will be prompted about popups being blocked. Do this:
  - Click the popup icon in the top right of the window
  - Change the radio button for "Always allow popups..."
  - Select "Done"
  - Close the popup window 
  - Select  "Launch" again
- Another popup about SSL may display briefly. Wait and it will disappear.
- Another orange screen may appear briefly. Wait and it will disappear.

4. Get a shell prompt for each node

*NOTE: If you are doing a reinstall and already have CoreOS installed on the nodes, you can ssh in as the core user. `ssh -i <path to private key from install> core@<node IP>. Otherwise follow the remaining instructions in this step.

You can use the RHEL 9 boot ISO to get a shell on a machine that does not have an operating system.

From the .30 desktop, download the RHEL 9 boot ISO. At the time of writing, it has already been downloaded to `/home/install/rhel-9.8-x86_64-boot.iso`.

In the Virtual Console for each node:

- Select "Connect Virtual Media"
- Under "Map CD/DVD", select "Choose File"
- Select the RHEL 9 boot .iso file.
- Select "Map Device"
- Confirm the bar at the top of the virtual console says "Virtual Media is connected", and "Devices Mapped: 1" and lists the name of your .iso file.
- Close the Virtual Media popup.
- From the iDRAC console for the node, power cycle the server.
- Switch back to the Virtual Console popup.
- Watch the top of the screen as the machine boots. There is a progress bar at the bottom, and a Dell symbol to the top left.
- Press the "Keyboard" button at the top of the window to bring up a virtual keyboard. Use this instead of your physical keyboard for the steps. You have to quickly press keys, and the input from your physical keyboard can sometimes be delayed in this interface.
- When the bar is approximately one third full, some text will appear to the right of the Dell symbol. As soon as that text appears option appears, quickly press `F11`.
- Close the virtual keyboard popup.
- You will see the text change to "Entering Boot Manager" with blue highlighting. Wait a minute.
- Select "One-shot UEFI Boot Menu"
- Select "Virtual Optical Drive"
- "Troubleshooting..."
- "Rescue a Red Hat Enterprise Linux..."
- Wait a few minutes
- When the menu appears, press 3 to skip to shell
- Press ENTER to continue

You should see a shell prompt.

# Useful commands to run on the node
```
lsblk # For storage device names
ip addr show # For MAC addresses
```

