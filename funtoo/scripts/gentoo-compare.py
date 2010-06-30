#!/usr/bin/python2

# This script will compare the versions of ebuilds in the funtoo portage tree against
# the versions of ebuilds in the target portage tree. Any higher versions in the 
# target Portage tree will be printed to stdout.

# Run this script from the root of the funtoo-overlay tree, specifying the target
# tree to compare against as an argument.

import portage.versions
import os,sys

if len(sys.argv) != 2:
	print "Please specify portage tree to compare against as first argument."
	sys.exit(1)

gportdir=sys.argv[1]

for cat in os.listdir("."):
	if cat == ".git":
		continue
	if not os.path.exists(gportdir+"/"+cat):
		continue
	if not os.path.isdir(gportdir+"/"+cat):
		continue
	for pkg in os.listdir(cat):
		if not os.path.exists("%s/%s/%s" % (gportdir, cat, pkg)):
			continue
		if not os.path.isdir("%s/%s" % (cat, pkg)):
			continue
		files = os.listdir("%s/%s" % (cat, pkg))
		ebuilds = []
		for file in files:
			if file[-12:] == "-9999.ebuild":
				continue
			if file[-7:] == ".ebuild":
				ebuilds.append("%s/%s" % (cat, file[:-7]))
		if ebuilds == []:
			print "dir %s/%s empty" % (cat, pkg)
			continue
		files = os.listdir("%s/%s/%s" % (gportdir, cat, pkg))
		gebuilds = []
		for file in files:
			if file[-12:] == "-9999.ebuild":
				# don't count -9999 ebuilds
				continue
			if file[-7:] == ".ebuild":
				gebuilds.append("%s/%s" % (cat, file[:-7]))
		fbest = portage.versions.best(ebuilds)
		gbest = portage.versions.best(gebuilds)
		if fbest == gbest:
			continue
		
		# a little trickery to ignore rev differences:

		fps = list(portage.versions.catpkgsplit(fbest))[1:]
		gps = list(portage.versions.catpkgsplit(gbest))[1:]
		gps[-1] = "r0"
		fps[-1] = "r0"
		mycmp = portage.versions.pkgcmp(fps, gps)
		if mycmp == -1:
			print gbest

