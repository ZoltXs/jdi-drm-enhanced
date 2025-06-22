# JDI DRM Enhanced Driver

Improved DRM driver for Sharp Memory LCD 2.7" screen (JDI & SHARP) with 400x240 resolution.

## Characteristics

- Full support for DRM (Direct Rendering Manager)

- Optimized for JDI LT027B5AC01 screen

- Support for color and monochrome

- Backlight control

- Advanced energy management

- Optimized SPI communication

- IOCTL interface for direct control

- Graphic overlays

## Installation

```bash

sudo make

sudo make install

Or use the installation script

sudo chmod +x install.sh

./install

```

## Configuration

The driver includes several configurable parameters:

- `backlight`: Enable/disable backlight (0/1)

- `mono_cutoff`: Grayscale threshold (0-255)

- `mono_invert`: Monochrome inversion (0/1)

- `auto_clear`: Clean screen when downloading driver (0/1)

- `color`: Enable color mode (0/1)

## Use

Once installed, the driver will appear as a standard DRM device in `/dev/dri/`.

## Supported Hardware

- JDI  (400x240)

- Sharp Memory LCD compatible

## Author

This driver is a version created by a Basque, N@Xs, improved and optimized of the sharp-drm driver of the master Ardangelo https://github.com/ardangelo/sharp-drm-driver

## Note

If you want to help me with my great work and support me in the construction of more projects like this, bring me a coffee ☕️.

It will also help me for the update of future drivers.

Click on this link to help me. 😜 👇👇

https://paypal.me/JbNoXs?country.x=ES&locale.x=es_ES


## License

GPL v2


# ColorBerry


# jdi screen driver

support debian 11 32-bit and debian 12 64-bit with raspberry pi, and debian 12 64-bit with orange pi zero 2w

# Raspberry PI

## Install

* remove old jdi-drm

  ```shell
  sudo vi /boot/config.txt   
  # /boot/firmware/config.txt for debian 12
  sudo vi /etc/modules 
  sudo rm -f /boot/overlays/jdi-drm.dtbo 
  ```
* remove old sharp-drm in apt if exist, and other packages depend on it.
* unzip file to /var/tmp/jdi-drm-rpi
* cd to /var/tmp/jdi-drm-rpi
* run `sudo make install`
* reboot

## Control backlight by side button

* put back.py in place like /home/username/sbin/back.py
* `chmod +x back.py`
* `sudo crontab -e`
* append `@reboot   sleep 5;/path/to/back.py`
* if it doesn't work in debian 12 64-bit, reinstall `python3-rpi.gpio`

### Set dithering level

```shell
echo <level> | sudo tee /sys/module/sharp_drm/parameters/dither > /dev/null
<level> from 0 to 4, 0 for close dithering, 4 for max
```

## .zshrc

```shell
if [ -z "$SSH_CONNECTION" ]; then
        if [[ "$(tty)" =~ /dev/tty ]] && type fbterm > /dev/null 2>&1; then
                fbterm
        # otherwise, start/attach to tmux
        elif [ -z "$TMUX" ] && type tmux >/dev/null 2>&1; then
                fcitx 2>/dev/null &
                tmux new -As "$(basename $(tty))"
        fi
fi
export PROMPT="%c$ "
export PATH=$PATH:~/sbin
export SDL_VIDEODRIVER="fbcon"
export SDL_FBDEV="/dev/fb1"
alias d0="echo 0 | sudo tee /sys/module/jdi_drm/parameters/dither"
alias d3="echo 3 | sudo tee /sys/module/jdi_drm/parameters/dither"
alias d4="echo 4 | sudo tee /sys/module/jdi_drm/parameters/dither"
alias b="echo 1 | sudo tee /sys/module/jdi_drm/parameters/backlit"
alias bn="echo 0 | sudo tee /sys/module/jdi_drm/parameters/backlit"
alias key='echo "keys" | sudo tee /sys/module/beepy_kbd/parameters/touch_as > /dev/null'
alias mouse='echo "mouse" | sudo tee /sys/module/beepy_kbd/parameters/touch_as > /dev/null'
```


# xfce

```bash
sudo apt install task-xfce-desktop
sudo apt-get install xserver-xorg-legacy
sudo usermod -a orangepi -G tty
```

## /etc/X11/Xwrapper.config

```
	allowed_users=anybody
	needs_root_rights=yes
```

## /etc/X11/xorg.conf

```


Section "Device"
    Identifier "FBDEV"
    Driver "fbdev"
    Option "fbdev" "/dev/fb0"
#    Option "ShadowFB" "false"
EndSection

Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
```
