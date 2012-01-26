# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/squeezeboxserver/files/Gentoo-plugins-README.txt,v 1.3 2010/04/25 22:26:28 lavajoe Exp $

The standard Squeezebox Server package is installed differently on Gentoo in
order that the installation complies with Gentoo's filesystem layout. These
notes are provided to give guidance for installing plugins within this
modified layout.

INSTALLING PLUGINS

The installation instructions of plugins should be followed but with the
following Gentoo specifics:

* Plugins should be installed into the directory:
  /var/lib/squeezeboxserver/Plugins
* Extension binaries (which sometimes accompany plugins) should be installed
  into the directory:
  /usr/lib/squeezeboxserver/Bin

BACKGROUND

Those interested can refer to the following for details of Gentoo's filesystem
standard:
http://devmanual.gentoo.org/general-concepts/filesystem/index.html
