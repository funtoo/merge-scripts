#!/usr/bin/python2

"""
This script copies the targets of 01-gentoo symlnks into the profile directory
within funtoo-overlay. It is designed to be run from the root of the funtoo
overlay, with the root of the gentoo portage tree passed as a first argument:

# cd /root/git/funtoo-overlay
# funtoo/scripts/copylinks.py /var/git/portage-gentoo

Then, all broken 01-gentoo symlinks will no longer be broken, as the source
files will now exist in funtoo-overlay.
"""

import os
import commands
import sys
s, x = commands.getstatusoutput("find -name 01-gentoo -type l")
for line in x.split():
	src=os.path.normpath(sys.argv[1]+"/"+os.path.dirname(line)+"/"+os.readlink(line))
	dest=os.path.normpath(os.getcwd()+"/"+src[len(sys.argv[1]):])
	os.system("install -d %s" % os.path.dirname(dest))
	os.system("cp %s %s" % ( src, dest ))
