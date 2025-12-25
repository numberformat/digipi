# NOAMi HAM Radio Digital Mode CyberDeck

This project is based on the DigiPi Project and it contains original code
and configuration by Craig, KM6LYW, and modifications to existing GPL code
that goes into the DigiPi project. For more information please see https://digipi.org/

Original author and maintainer: Craig, KM6LYW.

License: This NOAMi CyberDeck overlay is distributed under the terms of the
MIT License. Third-party components
bundled in this tree remain under their original licenses as noted in
`THIRD_PARTY_LICENSES.md`.

## Installation Instructions

The project is an overlay that goes on top of the stock raspberry pi OS. To setup the CyberDeck just follow these instructions exactly.

```sh
# create a raspberry pi SD card by installing the
# Raspberry Pi Imager software
#   Follow the Wizard interface to create the SD Card with the following customizations
#   Select the Raspberry Pi OS 32Bit With the Desktop interface
#   Customizations:
#   hostname: digipi
#   user: pi (this must be the pi user because its hard-coded in the overlay files) TODO: make it dynamic
#   wifi: configure your wifi. This is important for setup. Will not be needed later
#   remote access: enable ssh
# Write the image to SD card. Skip verify if you are in a hurry.
# Insert the SD card into your Pi and boot it up. First boot will take some time.
# It will show up on your network as digipi. You may ssh into it. If it does not connect a monitor and keyboard to it and see whats wrong.
# login as pi user using the password you selected.
git clone https://github.com/numberformat/digipi.git
cd digipi
./install.sh
# it will ask for your callsign
# navigate to http://digipi.lan (or whatever hostname your DHCP has given you)
```

## What this repo contains

This tree is essentially the “overlay” that turns a stock Raspberry Pi OS image into a NOAMi CyberDeck:

- `systemd/system/*.service` – units that define DigiPi operating modes and helpers:
  - Radio/digital‑mode services: `tnc.service`, `tnc300b.service`, `digipeater.service`, `node.service`, `winlinkrms.service`, `fldigi.service`, `js8call.service`, `wsjtx.service`, `sstv.service`, `ardop.service`, `pat.service`, `webchat.service`, plus `rigctld.service` for CAT/rig control.
  - Boot/network helpers: `digipi-boot.service` (initial DigiPi startup), `autohotspot.service` (create Wi‑Fi hotspot when no known SSID), and `digipi-resolv.service` (ensure `/run/resolv.conf` exists before networking).
- `home/pi/*` – user‑level scripts and configs that the services launch:
  - Shell wrappers like `fldigi.sh`, `wsjtx.sh`, `js8call.sh`, `sstv.sh`, `direwolf.*.sh`, `pat.sh`, `webchat.sh`, `online.sh`, etc.
  - Python utilities and small daemons such as `digibuttons.py`, `digibanner.py`, `direwatch.py`, and display drivers like `ILI9486.py`.
  - Application configuration for Fldigi, JS8Call, WSJT‑X, FLRig, and variants of Fldigi profiles.
- `usr/local/bin/*` – supporting binaries and helper scripts:
  - Direwolf and AX.25 tools (`direwolf*`, `kissutil`, `axdigi2018`, `ax25` helpers).
  - Winlink and packet tools (`piardopc*`, `rmsgw*`, `rmschanstat`, `convers`, `conversd.sh`).
  - Telemetry and APRS helpers (`decode_aprs`, `gen_packets`, `telem-*`, `gpsd-wrapper.sh`).
  - System utilities such as `cpufreq.sh`, `power.py`, `remount`, `ttyd.static`, `appserver`, and `node_web.sh`.
- `var/www/html/*` – the DigiPi web UI:
  - `index.php`, `index.service.php` and friends implement the front‑end used to select modes, view status, and run tools.
  - Additional pages provide Wi‑Fi and GPS configuration, ALSA/sound controls, system info/log views, APRS/Direwolf views, web chat, AX.25 calls, a limited shell, and setup flows.
- `etc/ax25/*` – AX.25 and packet radio configuration:
  - Port and routing definitions (`axports`, `nrports`, `nrbroadcast`, `rsports`, `rip98d.conf`).
  - Uronode and ax25d configuration (`uronode.*`, `ax25d.conf`, `axspawn.conf`, `ttylinkd.conf`, etc.) describing how packet/AX.25 services are exposed.

Together these files provide the services, web UI, and packet/digital‑mode plumbing that sit on top of Raspberry Pi OS to make it behave like a self‑contained HAM Radio Digital mode CyberDeck appliance.
