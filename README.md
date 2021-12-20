# Geohashing Wiki Helper

*Note: this project is still in active development, aiming for first release. It's reasonably usable, but may ruin your day without warning.*

This program aims to make using [Geohashing Wiki](https://geohashing.site) a bit less painful.

Currently, only uploading images and exporting resulting gallery is supported, but this is probably the most annoying part of creating your geohashing report anyways.

I believe interface is simple enough to make program fall into "tools that don't need documentation" category.

## Dependencies

This program is written in Vala (0.54, use [Vala Next PPA](https://launchpad.net/~vala-team/+archive/ubuntu/next) on Ubuntu derivatives) and uses Meson build system. Additionally, the following libraries are required:

* GTK+ 3
* libsoup-2.4 (and glib-networking at runtime for TLS support)
* json-glib-1.0

It should be fully compatible with every platform that those libraries support (Linux, Windows, OS X), but only was tested on Linux.
