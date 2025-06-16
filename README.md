# JDI DRM Enhanced Driver

Improved DRM driver for Sharp Memory LCD 2.7" screen (JDI LT027B5AC01) with 400x240 resolution.

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

- JDI LT027B5AC01 (400x240)

- Sharp Memory LCD compatible

## Author

This driver is a version created by a Basque, N@Xs, improved and optimized of the sharp-drm driver of the master Ardangelo https://github.com/ardangelo/sharp-drm-driver

## License

GPL v2
