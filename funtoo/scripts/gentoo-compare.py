#!/usr/bin/python2

# This script will compare the versions of ebuilds in the funtoo portage tree against
# the versions of ebuilds in the target portage tree. Any higher versions in the 
# target Portage tree will be printed to stdout.

# Run this script from the root of the funtoo-overlay tree, specifying the target
# tree to compare against as an argument.

import portage.versions
import os,sys
import commands

def keywords(portdir, ebuild):
	return commands.getoutput("funtoo/scripts/keywords.sh %s %s" % ( portdir, ebuild ) )

if len(sys.argv) != 2:
	print "Please specify portage tree to compare against as first argument."
	sys.exit(1)

gportdir=sys.argv[1]

print "Package comparison - ebuilds not in (~)amd64 and (~)x86 are not considered."
print

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
		
		abort = False
		while True:
			fbest = portage.versions.best(ebuilds)
			if fbest == "":
				abort = True
				break
			fkeywords = keywords(".", "%s/%s/%s.ebuild" % (cat, pkg, fbest.split("/")[1] )).split()
			if "~amd64" in fkeywords or "~x86" in fkeywords or "x86" in fkeywords or "amd64" in fkeywords:
				break
			ebuilds.remove(fbest)
			
		if abort:
			continue

		while True:
			gbest = portage.versions.best(gebuilds)
			if gbest == "":
				abort = True
				break
			gkeywords = keywords(gportdir, "%s/%s/%s.ebuild" % (cat, pkg, gbest.split("/")[1] )).split()
			if "~amd64" in gkeywords or "~x86" in gkeywords or "x86" in gkeywords or "amd64" in gkeywords:
				break
			gebuilds.remove(gbest)
	
		if abort:
			continue

		if fbest == gbest:
			continue
		
		# a little trickery to ignore rev differences:

		fps = list(portage.versions.catpkgsplit(fbest))[1:]
		gps = list(portage.versions.catpkgsplit(gbest))[1:]
		gps[-1] = "r0"
		fps[-1] = "r0"
		mycmp = portage.versions.pkgcmp(fps, gps)
		if mycmp == -1:
			print "%s (vs. %s in funtoo)" % ( gbest, fbest )
