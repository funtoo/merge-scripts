#!/usr/bin/python2

import os
import subprocess
import portage.versions

# PortageRepository provides an easy-to-use and elegant means of accessing an
# on-disk Gentoo/Funtoo Portage repository. It is designed to allow for some
# abstraction of the underlying repository, *as long as* the underlying
# abstraction understands filesystem paths and follows a conventional Portage
# layout. So, you could create a PortageRepository subclass that accessed a
# remote Portage repository, or accessed the contents of .git metadata to view
# the repository, since both of these subclasses could understand paths and can
# store a conventional Portage repository layout.

# This class has minimal dependencies, utilizing only "portage.versions" from
# the official Portage sources for version splitting, etc. This allows this
# code to be easily used by utility programs.

# If you need to store a Portage repository in a relational database, or query
# a database using JSON or SOAP, and by just specifying category and package
# names, then this class isn't ideal, and you should probably create a new
# class for this purpose. I could have made this class handle every crazy
# scenario but the best bang for the buck in terms of elegance and
# maintainability was to "bake in" the notion of a consistent, traditional
# Portage filesystem layout. In particular, the getOwner() method uses this
# convention to figure out which overlay is the owner of a particular file.
# It keeps things simple.

class PortageRepository(object):

	def __repr__(self):
		return "PortageRepository(%s)" % self.base_path

	def grabfile(self,path):

		# grabfile() is a simple helper method that grabs the contents
		# of a typical portage configuration file, minus any lines
		# beginning with "#", and returns each line as an item in a
		# list. Newlines are stripped. This helper function looks at
		# the repository base_path, not any children (overlays).

		out=[]	
		if not os.path.exists(path):
			return out
		if os.path.isdir(path):
			print "ISDIR"
			scan = os.listdir(path)
			scan = map(lambda(x): "%s/%s" % ( path, x ), scan )
			print scan
		else:
			scan = [ path ]
		for path in scan:
			a=open(path,"r")
			for line in a.readlines():
				if len(line) and line[0] != "#":
					out.append(line[:-1])
			a.close()
		return out
	
	def grabebuilds(self,path,cat,pkg):

		# grabebuilds() is another simple helper method that will
		# return a list of cpvs (ie. "foo/bar-1.0") in a list that
		# represent the ebuilds that exist on disk in this particular
		# repository. This helper function looks at the repository
		# base_path, not any children (overlays).

		out=[]
		fullpath = "%s/%s/%s" % ( path, cat, pkg )
		if not os.path.exists(fullpath):
			return out
		for file in os.listdir(fullpath):
			if file[-7:] == ".ebuild":
				out.append("%s/%s" % ( cat, file[:-7] ))
		return out

	def __init__(self,base_path, **args):

		# initialize variables. Also note that self.children contains a
		# list of child overlays, which in turn can have their own
		# child overlays. Overlays at the beginning of the
		# self.overlays list have precedence.
		#
		# Rather than provide overlay access methods, you just set these
		# manually, like this:
		#
		# a = PortageRepository("/usr/portage")
		# b = PortageRepository("/var/tmp/git/funtoo-overlay",overlay=True)
		# a.children = [b]

		self.base_path = base_path
		self.children = []
		if "overlay" in args and args["overlay"] == True:
			self.overlay = True
		else:
			self.overlay = False

	@property
	def overlays(self):
		out=[]
		for child in self.children:
			out.append(child.base_path)
		return " ".join(out)

	@property
	def info_pkgs(self,recurse=True):
		return self.__grabset__("profiles/info_pkgs",recurse)

	@property
	def info_vars(self,recurse=True):
		return self.__grabset__("profiles/info_vars",recurse)

	@property
	def categories(self,recurse=True):
		# This property will return a set containing all valid
		# categories. By default, overlays are scanned as well.
		return self.__grabset__("profiles/categories",recurse)

	def __grabset__(self,path,recurse=True):
		out = set(self.grabfile(self.base_path+"/"+path))
		if recurse:
			for overlay in self.children:
				out = out | overlay.__grabset__(path)
		return out

	def packages(self,cat,pkg,recurse=True):

		# This property will return a set containing all ebuilds
		# (in cpv format) of a particular category and package
		# name that exist in the repository. By default, overlays
		# are scanned as well.

		ebs = set(self.grabebuilds(self.base_path,cat,pkg))
		if recurse:
			for overlay in self.children:
				ebs = ebs | overlay.packages(cat,pkg)
		return ebs

	def getOwner(self,file,recurse=True):

		# getOwner() can be used to figure out which repository
		# owns a particular file. You specify the file, and
		# you'll get a reference to the repository object that
		# owns the file. By default, children (overlays) are
		# scanned as well.

		if recurse:
			for overlay in self.children:
				a = overlay.getOwner(file)
				if a != None:
					return a
		if os.path.exists(self.base_path+"/"+file):
			return self
		else:
			return None

	def do(self,action,ebuild):
		env = {
			"PORTAGE_TMPDIR" : "/var/tmp/portage",
			"EBUILD" : ebuild,
			"EBUILD_PHASE" : action,
			"ECLASSDIR" : self.base_path+"/eclass",
			"PORTDIR" : self.base_path,
			"PORTDIR_OVERLAY" : self.overlays,
			"PORTAGE_GID" : "250",
			"CATEGORY" : "sys-boot",
			"PF" : "grub-1.98-r1",
			"P" : "grub",
			"PV" : "1.98",
			"dbkey" : "/var/tmp/foob/boob"
		}
		retval = subprocess.call(["/usr/lib/portage/bin/ebuild.sh",action],env=env)

a=PortageRepository("/usr/portage-gentoo")
b=PortageRepository("/root/git/funtoo-overlay",overlay=True)
a.children=[b]
print a.categories
print a.packages("sys-apps","portage")
print a.packages("sys-apps","portage",recurse=False)
print a.getOwner("sys-apps/portage/portage-2.2_rc67-r1.ebuild")
print a.getOwner("eclass/eutils.eclass")
print a.getOwner("eclass/autotools.eclass")
print a.info_pkgs
print a.info_vars
print a.grabfile(a.base_path+"/profiles/package.mask")
c=EbuildWrapper()
c.do("depend","/root/git/funtoo-overlay/sys-boot/grub/grub-1.98-r1.ebuild")
