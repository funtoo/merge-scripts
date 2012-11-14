#!/usr/bin/python
import portage, os, sys
kw=portage.settings["ACCEPT_KEYWORDS"].split()
root=portage.settings["ROOT"]
outfile=os.path.join(root,"/etc/portage/make.profile/parent")
oldlink=os.path.join(root,"/etc/make.profile")
if not os.path.lexists(oldlink) and os.path.exists(outfile):
	print("System appears upgraded to new profile system.")
	sys.exit(0)
if "~amd64" in kw:
	new_arch = "x86-64bit"
	new_build = "current"
elif "amd64" in kw:
	new_arch = "x86-64bit"
	new_build = "stable"
elif "~x86" in kw:
	new_arch = "x86-32bit"
	new_build = "current"
elif "x86" in kw:
	new_arch = "x86-32bit"
	new_build = "stable"
else:
	print("Couldn't determine system architecture and build. Please upgrade to new system manually.")
	sys.exit(1)
of=os.readlink(oldlink).split("/")[-1]
if of in [ "server", "desktop" ]:
	flavor=of
else:
	flavor="core"

print("Detected architecture %s, build %s" % ( new_arch, new_build ))
try:
	if not os.path.exists(os.path.dirname(outfile)):
		os.makedirs(os.path.dirname(outfile))
	pf=open(outfile,"w")
	pf.write("gentoo:funtoo/1.0/linux-gnu/arch/%s\n" % new_arch )
	pf.write("gentoo:funtoo/1.0/linux-gnu/build/%s\n" % new_build )
	pf.write("gentoo:funtoo/1.0/linux-gnu/flavor/%s\n" % flavor )
	pf.close()
	if os.path.lexists(oldlink):
		os.unlink(oldlink)
except IOError:
	print("Encountered error when upgrading to new profile system.")
	sys.exit(2)
	
print("Upgraded to new profile system.")
