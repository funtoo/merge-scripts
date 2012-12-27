# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

The standard Logitech Media Server package is installed differently on Gentoo
in order that the installation complies with Gentoo's filesystem layout. These
notes are provided to give guidance for installing plugins within this
modified layout.

MANUALLY INSTALLING PLUGINS

The installation instructions of plugins should be followed but with the
following Gentoo specifics:

* Plugins should be installed into the directory:
  /var/lib/logitechmediaserver/Plugins
* Extension binaries (which sometimes accompany plugins) should be installed
  into the directory:
  /opt/logitechmediaserver/Bin

BACKGROUND

Those interested can refer to the following for details of Gentoo's filesystem
standard:
http://devmanual.gentoo.org/general-concepts/filesystem/index.html
